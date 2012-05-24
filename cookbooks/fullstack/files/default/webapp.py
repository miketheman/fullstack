#!/usr/bin/env python
'''
This application is a simple implemnetation of a word counter.
It leverages the bottle micro-framework, as well as pymongo.
'''

import time
from functools import wraps
from bottle import route, run, response, request
from bson.json_util import default
import pymongo
from pymongo.uri_parser import parse_uri
import json

try:
    import local_settings as config
except ImportError:
    # make default config: non-replset connection
    # directly to mongo on localhost
    class config(object):
        mongo_uri = 'mongodb://localhost'
        
mongo_uri = getattr(config, 'mongo_uri', 'mongodb://localhost')
uri_components = parse_uri(mongo_uri)
if 'replicaSet' in uri_components['options']:
    conn = pymongo.ReplicaSetConnection(mongo_uri)
else:
    conn = pymongo.Connection(mongo_uri)

db = conn.test

def add_perf_timings(name=None):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            start = time.time()
            rv = func(*args, **kwargs)
            end = time.time()
            # TODO: Ship this off to somewhere else - statsd, graphite, etc
            # db.request_took.insert(
            #       {'path': name or request.path, 'seconds': (end - start)})
            response.set_header('X-Took-Seconds', (end - start))
            return rv
        return wrapper
    return decorator


@route('/insert/:name')
@add_perf_timings(name='record insert')
def insert(name):
    doc = {'name': name}
    db.phrases.update(doc, {"$inc":{"count": 1}}, upsert=True)
    
    # TODO: Figure out a better place for this - some sort of setup url?
    db.phrases.ensure_index('name')
    db.phrases.ensure_index('count')
    
    return json.dumps(doc, default=default)


@route('/get')
@route('/get/:name')
@add_perf_timings(name='record get')
def get(name=None):
    query = {}
    if name is not None:
        query['name'] = name
        
    response.set_header('Content-Type', 'application/json')
    return json.dumps(list(db.phrases.find(query)), default=default)

@route('/toplist')
@add_perf_timings(name='top records list')
def toplist(name=None):
    
    # TODO: Figure out a better place for this - some sort of setup url?
    db.phrases.ensure_index('name')
    db.phrases.ensure_index('count')
    
    query = db.phrases.find({}, ['count', 'name']).sort('count', -1).limit(10)
    
    response.set_header('Content-Type', 'application/json')
    return json.dumps(list(query), default=default)


# This is because I hate seeing errors for no reason.
@route('/favicon.ico')
def favicon():
    return

if __name__ == '__main__':
    run(host='localhost', port=8080, reloader=True)