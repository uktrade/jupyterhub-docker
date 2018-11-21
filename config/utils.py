import datetime
import hashlib
import hmac
import itertools
import urllib


def normalise_environment(key_values):
    ''' Converts denormalised dict of (string -> string) pairs, where the first string
        is treated as a path into a nested list/dictionary structure

        {
            "FOO__1__BAR": "setting-1",
            "FOO__1__BAZ": "setting-2",
            "FOO__2__FOO": "setting-3",
            "FOO__2__BAR": "setting-4",
            "FIZZ": "setting-5",
        }

        to the nested structure that this represents

        {
            "FOO": [{
                "BAR": "setting-1",
                "BAZ": "setting-2",
            }, {
                "BAR": "setting-3",
                "BAZ": "setting-4",
            }],
            "FIZZ": "setting-5",
        }

        If all the keys for that level parse as integers, then it's treated as a list
        with the actual keys only used for sorting

        This function is recursive, but it would be extremely difficult to hit a stack
        limit, and this function would typically by called once at the start of a
        program, so efficiency isn't too much of a concern.
    '''

    # Separator is chosen to
    # - show the structure of variables fairly easily;
    # - avoid problems, since underscores are usual in environment variables
    separator = '__'

    def get_first_component(key):
        return key.split(separator)[0]

    def get_later_components(key):
        return separator.join(key.split(separator)[1:])

    without_more_components = {
        key: value
        for key, value in key_values.items()
        if not get_later_components(key)
    }

    with_more_components = {
        key: value
        for key, value in key_values.items()
        if get_later_components(key)
    }

    def grouped_by_first_component(items):
        def by_first_component(item):
            return get_first_component(item[0])

        # groupby requires the items to be sorted by the grouping key
        return itertools.groupby(
            sorted(items, key=by_first_component),
            by_first_component,
        )

    def items_with_first_component(items, first_component):
        return {
            get_later_components(key): value
            for key, value in items
            if get_first_component(key) == first_component
        }

    nested_structured_dict = {
        **without_more_components, **{
            first_component: normalise_environment(
                items_with_first_component(items, first_component))
            for first_component, items in grouped_by_first_component(with_more_components.items())
        }}

    def all_keys_are_ints():
        def is_int(string_to_test):
            try:
                int(string_to_test)
                return True
            except ValueError:
                return False

        return all([is_int(key) for key, value in nested_structured_dict.items()])

    def list_sorted_by_int_key():
        return [
            value
            for key, value in sorted(
                nested_structured_dict.items(),
                key=lambda key_value: int(key_value[0])
            )
        ]

    return \
        list_sorted_by_int_key() if all_keys_are_ints() else \
        nested_structured_dict


def aws_headers(service, access_key_id, secret_access_key,
                 region, host, method, path, query, pre_auth_headers, payload):
    algorithm = 'AWS4-HMAC-SHA256'

    now = datetime.datetime.utcnow()
    amzdate = now.strftime('%Y%m%dT%H%M%SZ')
    datestamp = now.strftime('%Y%m%d')
    credential_scope = f'{datestamp}/{region}/{service}/aws4_request'
    headers_lower = {
        header_key.lower().strip(): header_value.strip()
        for header_key, header_value in pre_auth_headers.items()
    }
    required_headers = ['host', 'x-amz-content-sha256', 'x-amz-date']
    signed_header_keys = sorted([header_key
                                 for header_key in headers_lower.keys()] + required_headers)
    signed_headers = ';'.join(signed_header_keys)
    payload_hash = hashlib.sha256(payload).hexdigest()

    def signature():
        def canonical_request():
            header_values = {
                **headers_lower,
                'host': host,
                'x-amz-content-sha256': payload_hash,
                'x-amz-date': amzdate,
            }

            canonical_uri = urllib.parse.quote(path, safe='/~')
            query_keys = sorted(query.keys())
            canonical_querystring = '&'.join([
                urllib.parse.quote(key, safe='~') + '=' + urllib.parse.quote(query[key], safe='~')
                for key in query_keys
            ])
            canonical_headers = ''.join([
                header_key + ':' + header_values[header_key] + '\n'
                for header_key in signed_header_keys
            ])

            return f'{method}\n{canonical_uri}\n{canonical_querystring}\n' + \
                   f'{canonical_headers}\n{signed_headers}\n{payload_hash}'

        def sign(key, msg):
            return hmac.new(key, msg.encode('utf-8'), hashlib.sha256).digest()

        string_to_sign = \
            f'{algorithm}\n{amzdate}\n{credential_scope}\n' + \
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
        'Authorization': (
            f'{algorithm} Credential={access_key_id}/{credential_scope}, ' +
            f'SignedHeaders={signed_headers}, Signature=' + signature()
        ),
    }
