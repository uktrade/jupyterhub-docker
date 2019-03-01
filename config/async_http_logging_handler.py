import logging

from tornado import gen
from tornado.httpclient import (
    HTTPRequest,
)
import tornado.ioloop


class AsyncHTTPLoggingHandler(logging.Handler):

    def __init__(self, ioloop, client, host, port, path):
        super().__init__()
        self.ioloop = ioloop
        self.client = client
        self.host = host
        self.port = port
        self.path = path

    def emit(self, record):
        try:
            message = self.format(record)
        except BaseException:
            return

        # Bit of a fudge to avoid infinite loops, since
        # we're using Tornado to log Tornado messages
        if 'max_clients limit reached' in message or self.host in message:
            return

        try:
            url = f'https://{self.host}:{self.port}{self.path}'
            self.ioloop.add_callback(post_record, self.client, url, message)
        except BaseException:
            self.handleError(record)

@gen.coroutine
def post_record(client, url, message):
    try:
        request = HTTPRequest(
            url, method='POST',
            body=message.encode('utf-8') + b'\n',
            request_timeout=2,
        )
        yield client.fetch(request)
    except BaseException:
        pass
