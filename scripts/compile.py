#!/usr/bin/python3

import subprocess, os, sys, shutil, re

def get_mtime(f):
    return os.stat(f).st_mtime

def replace_ext(s, ext):
    s = s.split('/')
    s[-1] = re.sub('\.[^$]+', '.' + ext, s[-1])
    return os.path.join(*s)

def compile_file(src, dest):
    fennel = os.path.join(os.getenv('HOME'), '.config', 'nvim', 'scripts', 'fennel')
    command = [fennel, '-c', src]
    run_command = lambda command: subprocess.run(command, check=True, capture_output=True)
    get_output = lambda j: j.stdout.decode().split("\n")
    j = None

    try:
        if os.path.exists(dest):
            if get_mtime(dest) < get_mtime(src):
                j = subprocess.run(command, check=True, capture_output=True)
        else:
            j = subprocess.run(command, check=True, capture_output=True)

        if j:
            print('Compiled: ' + src)
            with open(dest, 'w') as fh:
                fh.write(j.stdout.decode())
        else:
            print('Skipped: ' + src)

    except subprocess.CalledProcessError as e:
        print(e)
        sys.exit(1)


def get_files(d):
    '''Depends on external dependency: fd'''
    os.chdir(d)
    j = subprocess.run(['fd', 'fnl$', '.'], capture_output=True, check=True)
    files = list(filter(lambda s: len(s) > 0, j.stdout.decode().split("\n")))
    files = list(map(lambda s: s.replace('./', ''), files))

    return files

config_dir = os.path.join(os.getenv('HOME'), '.config', 'nvim')
target = os.path.join(config_dir, 'lua')
source = os.path.join(config_dir, 'fnl')

for i in get_files(source):
    compile_file(i, os.path.join(target, replace_ext(i, 'lua')))

