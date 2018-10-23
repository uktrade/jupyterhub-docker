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

        message = record.getMessage()
        # Bit of a fudge to avoid infinite loops, since
        # we're using Tornado to log Tornado messages
        if 'max_clients limit reached' or self.host in message:
            return

        @gen.coroutine
        def post_record():
            try:
                request = HTTPRequest(
                    f'https://{self.host}:{self.port}{self.path}', method='POST',
                    body=message.encode('utf-8'),
                )
                yield self.client.fetch(request)
            except BaseException:
                self.handleError(record)

        try:
            self.ioloop.add_callback(post_record)
        except BaseException:
            self.handleError(record)
