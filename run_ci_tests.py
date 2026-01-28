#!/usr/bin/env python3

import argparse
import os
import subprocess
import toml

HOME = os.path.dirname(os.path.realpath(__file__))

def main():
    parser = argparse.ArgumentParser(prog='CI')
    parser.add_argument('names', nargs='+')
    parser.add_argument('-e', '--engine', help='the container engine to use')
    parser.add_argument(
        '-v',
        '--verbose',
        action='store_true',
        help='print verbose diagnostic output',
    )
    args = parser.parse_args()
    if args.engine is None:
        args.engine = os.environ.get('CROSS_CONTAINER_ENGINE', 'docker')

    with open(os.path.join(HOME, 'targets.toml')) as file:
        matrix = toml.loads(file.read())
        matrix = {i['name']: i for i in matrix['target']}

    for name in args.names:
        target = matrix[name]
        command = [
            'cargo',
            'build-docker-image',
            name,
            '--engine',
            args.engine,
            '--tag',
            'main'
        ]
        if args.verbose:
            command.append('--verbose')
            print(f'Running build command "{" ".join(command)}"')
        subprocess.run(command, check=True)

        # add our environment and run our tests
        env = dict(os.environ)
        cross_env = {}
        key = f'CROSS_TARGET_{target["target"].upper().replace("-", "_")}_IMAGE'
        image = f'ghcr.io/cross-rs/{target["target"]}:main'
        cross_env[key] = image
        cross_env['TARGET'] = target['target']
        cross_env['CROSS_CONTAINER_ENGINE'] = args.engine
        for key in ('cpp', 'dylib', 'std', 'build-std', 'run', 'runners'):
            value = target.get(key)
            if value:
                key = key.upper().replace('-', '_')
                if value is True:
                    value = '1'
                cross_env[key] = value
        env.update(cross_env)
        if args.verbose:
            print(f'Running test command with env of "{cross_env}"')
        subprocess.run(['ci/test.sh'], env=env, check=True)

if __name__ == '__main__':
    main()
