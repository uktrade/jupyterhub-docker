import asyncio
import contextlib
from collections import (
    namedtuple,
)
from datetime import (
    datetime,
)
import hashlib
import hmac
import json
import logging
import os
import sys
import signal
import urllib


import aiohttp
from bs4 import (
    BeautifulSoup,
)

AwsCredentials = namedtuple('AwsCredentials', [
    'access_key_id', 'secret_access_key', 'pre_auth_headers',
])

S3Bucket = namedtuple('AwsS3Bucket', [
    'region', 'host', 'verify_certs', 'name',
])

S3Context = namedtuple('Context', [
    'session', 'credentials', 'bucket',
])


async def aws_request(logger, session, service, region, host, verify_certs,
                      credentials, method, full_path, query, api_pre_auth_headers,
                      payload, payload_hash):
    creds = await credentials(logger, session)
    pre_auth_headers = {
        **api_pre_auth_headers,
        **creds.pre_auth_headers,
    }

    headers = _aws_sig_v4_headers(
        creds.access_key_id, creds.secret_access_key, pre_auth_headers,
        service, region, host, method, full_path, query, payload_hash,
    )

    querystring = urllib.parse.urlencode(query, safe='~', quote_via=urllib.parse.quote)
    encoded_path = urllib.parse.quote(full_path, safe='/~')
    url = f'https://{host}{encoded_path}' + (('?' + querystring) if querystring else '')

    # aiohttp seems to treat both ssl=False and ssl=True as config to _not_ verify certificates
    ssl = {} if verify_certs else {'ssl': False}
    return session.request(method, url, headers=headers, data=payload, **ssl)


def _aws_sig_v4_headers(access_key_id, secret_access_key, pre_auth_headers,
                        service, region, host, method, path, query, payload_hash):
    algorithm = 'AWS4-HMAC-SHA256'

    now = datetime.utcnow()
    amzdate = now.strftime('%Y%m%dT%H%M%SZ')
    datestamp = now.strftime('%Y%m%d')
    credential_scope = f'{datestamp}/{region}/{service}/aws4_request'

    pre_auth_headers_lower = {
        header_key.lower(): ' '.join(header_value.split())
        for header_key, header_value in pre_auth_headers.items()
    }
    required_headers = {
        'host': host,
        'x-amz-content-sha256': payload_hash,
        'x-amz-date': amzdate,
    }
    headers = {**pre_auth_headers_lower, **required_headers}
    header_keys = sorted(headers.keys())
    signed_headers = ';'.join(header_keys)

    def signature():
        def canonical_request():
            canonical_uri = urllib.parse.quote(path, safe='/~')
            quoted_query = sorted(
                (urllib.parse.quote(key, safe='~'), urllib.parse.quote(value, safe='~'))
                for key, value in query.items()
            )
            canonical_querystring = '&'.join(f'{key}={value}' for key, value in quoted_query)
            canonical_headers = ''.join(f'{key}:{headers[key]}\n' for key in header_keys)

            return f'{method}\n{canonical_uri}\n{canonical_querystring}\n' + \
                   f'{canonical_headers}\n{signed_headers}\n{payload_hash}'

        def sign(key, msg):
            return hmac.new(key, msg.encode('utf-8'), hashlib.sha256).digest()

        string_to_sign = f'{algorithm}\n{amzdate}\n{credential_scope}\n' + \
                         hashlib.sha256(canonical_request().encode('utf-8')).hexdigest()

        date_key = sign(('AWS4' + secret_access_key).encode('utf-8'), datestamp)
        region_key = sign(date_key, region)
        service_key = sign(region_key, service)
        request_key = sign(service_key, 'aws4_request')
        return sign(request_key, string_to_sign).hex()

    return {
        **pre_auth_headers,
        'x-amz-date': amzdate,
        'x-amz-content-sha256': payload_hash,
        'Authorization': f'{algorithm} Credential={access_key_id}/{credential_scope}, '
                         f'SignedHeaders={signed_headers}, Signature=' + signature(),
    }


async def s3_request_full(logger, context, method, path, query, api_pre_auth_headers,
                          payload, payload_hash):

    with logged(logger, 'Request: %s %s %s %s %s',
                [method, context.bucket.host, path, query, api_pre_auth_headers]):
        async with await _s3_request(logger, context, method, path, query, api_pre_auth_headers,
                                     payload, payload_hash) as result:
            return result, await result.read()


async def _s3_request(logger, context, method, path, query, api_pre_auth_headers,
                      payload, payload_hash):
    bucket = context.bucket
    return await aws_request(
        logger, context.session, 's3', bucket.region, bucket.host, bucket.verify_certs,
        context.credentials, method, f'/{bucket.name}{path}', query, api_pre_auth_headers,
        payload, payload_hash)


def s3_hash(payload):
    return hashlib.sha256(payload).hexdigest()


@contextlib.contextmanager
def logged(logger, message, logger_args):
    try:
        logger.debug(message + '...', *logger_args)
        status = 'done'
        logger_func = logger.debug
        yield
    except asyncio.CancelledError:
        status = 'cancelled'
        logger_func = logger.debug
        raise
    except BaseException:
        status = 'failed'
        logger_func = logger.exception
        raise
    finally:

        logger_func(message + '... (%s)', *(logger_args + [status]))


def get_ecs_role_credentials(url):

    aws_access_key_id = None
    aws_secret_access_key = None
    token = None
    expiration = datetime(1900, 1, 1)

    async def get(logger, session):
        nonlocal aws_access_key_id
        nonlocal aws_secret_access_key
        nonlocal token
        nonlocal expiration

        now = datetime.now()

        if now > expiration:
            method = 'GET'
            with logged(logger, 'Requesting temporary credentials from %s', [url]):
                async with session.request(method, url) as response:
                    response.raise_for_status()
                    creds = json.loads(await response.read())

            aws_access_key_id = creds['AccessKeyId']
            aws_secret_access_key = creds['SecretAccessKey']
            token = creds['Token']
            expiration = datetime.strptime(creds['Expiration'], '%Y-%m-%dT%H:%M:%SZ')

        return AwsCredentials(
            access_key_id=aws_access_key_id,
            secret_access_key=aws_secret_access_key,
            pre_auth_headers={
                'x-amz-security-token': token,
            },
        )

    return get


async def async_main(loop, logger):
    session = aiohttp.ClientSession(loop=loop)

    credentials = get_ecs_role_credentials('http://169.254.170.2' + os.environ['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'])
    bucket = S3Bucket(
      region=os.environ['MIRRORS_BUCKET_REGION'],
      host=os.environ['MIRRORS_BUCKET_HOST'],
      verify_certs=True,
      name=os.environ['MIRRORS_BUCKET_NAME'],
    )
    s3_context = S3Context(
        session=session,
        credentials=credentials,
        bucket=bucket,
    )

    cran_task = asyncio.ensure_future(cran_mirror(logger, session, s3_context))
    conda_task = asyncio.ensure_future(conda_forge_mirror(logger, session, s3_context))
    
    await cran_task
    await conda_task

    await session.close()
    await asyncio.sleep(0)


async def cran_mirror(logger, session, s3_context):
    source_base_url = 'https://cran.ma.imperial.ac.uk/web/packages/available_packages_by_name.html'
    source_base_parsed = urllib.parse.urlparse(source_base_url)
    cran_prefix = 'cran/'

    done = set()
    queue = asyncio.Queue()
    await queue.put(source_base_url)

    async def transfer_task():
        while True:
            url = await queue.get()

            try:
                async with session.get(url) as response:
                    response.raise_for_status()
                    content_type = response.headers['Content-Type']
                    data = await response.read()

                key_suffix = urllib.parse.urlparse(url).path[1:]  # Without leading /
                target_key = cran_prefix + key_suffix
                response, _ = await s3_request_full(
                    logger, s3_context, 'PUT', '/' + target_key, {}, {}, data, s3_hash(data))
                response.raise_for_status()

                if content_type == 'text/html':
                    soup = BeautifulSoup(data, 'html.parser')
                    links = soup.find_all('a')
                    for link in links:
                        absolute = urllib.parse.urljoin(url, link.get('href'))
                        absolute_no_frag = absolute.split('#')[0]
                        if urllib.parse.urlparse(absolute_no_frag).netloc == source_base_parsed.netloc and absolute_no_frag not in done:
                            await queue.put(absolute_no_frag)
                            done.add(absolute_no_frag)

            except:
                logger.exception('Exception crawling %s', url)
            finally:
                queue.task_done()

    tasks = [
        asyncio.ensure_future(transfer_task()) for _ in range(0, 10)
    ]
    try:
        await queue.join()
    finally:
        for task in tasks:
            task.cancel()
        await asyncio.sleep(0)


async def conda_forge_mirror(logger, session, s3_context):
    source_base_url = 'https://conda.anaconda.org/conda-forge/'
    arch_dirs = ['noarch/', 'linux-64/']
    conda_forge_prefix = 'conda-forge/'

    repodatas = []
    queue = asyncio.Queue()

    for arch_dir in arch_dirs:
        async with session.get(source_base_url + arch_dir + 'repodata.json') as response:
            response.raise_for_status()
            source_repodata_raw = await response.read()
            source_repodata = json.loads(source_repodata_raw)

            for package_suffix, _ in source_repodata['packages'].items():
                await queue.put(arch_dir + package_suffix)

            repodatas.append((arch_dir + 'repodata.json', source_repodata_raw))

        async with session.get(source_base_url + arch_dir + 'repodata.json.bz2') as response:
            response.raise_for_status()
            repodatas.append((arch_dir + 'repodata.json.bz2', await response.read()))

    async def transfer_task():
        while True:
            package_suffix = await queue.get()

            try:
                source_package_url = source_base_url + package_suffix
                target_package_key = conda_forge_prefix + package_suffix

                async with session.get(source_package_url) as response:
                    response.raise_for_status()
                    data = await response.read()

                response, _ = await s3_request_full(
                    logger, s3_context, 'PUT', '/' + target_package_key, {}, {}, data, s3_hash(data))
                response.raise_for_status()
            except:
                logger.exception('Exception transferring %s', package_suffix)
            finally:
                queue.task_done()

    tasks = [
        asyncio.ensure_future(transfer_task()) for _ in range(0, 10)
    ]
    try:
        await queue.join()
    finally:
        for task in tasks:
            task.cancel()
        await asyncio.sleep(0)

    for path, data in repodatas:
        target_repodata_key = conda_forge_prefix + path
        response, _ = await s3_request_full(
                logger, s3_context, 'PUT', '/' + target_repodata_key, {}, {},
                data, s3_hash(data))
        response.raise_for_status()


def main():
    loop = asyncio.get_event_loop()

    logger = logging.getLogger()
    logger.setLevel(logging.DEBUG)

    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(logging.DEBUG)
    logger.addHandler(handler)

    listening = asyncio.Event()
    main_task = loop.create_task(async_main(loop, logger))
    loop.add_signal_handler(signal.SIGINT, main_task.cancel)
    loop.add_signal_handler(signal.SIGTERM, main_task.cancel)

    loop.run_until_complete(main_task)

    logger.debug('Exiting.')


if __name__ == '__main__':
    main()
