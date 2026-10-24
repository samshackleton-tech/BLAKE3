import subprocess,sys,re
repo,commit,b3=sys.argv[1:4]
lock=subprocess.run(['git','-C',repo,'show',f'{commit}:Cargo.lock'],capture_output=True,text=True,check=True).stdout
def h(t): return subprocess.run([b3],input=t.encode(),capture_output=True,check=True).stdout.decode()[:10]
blocks=lock.split('\n[[package]]\n')
def drop_source(pkg):
    out=[]
    for b in blocks:
        if re.search(rf'^name = "{pkg}"$', b, re.M):
            b='\n'.join(l for l in b.split('\n') if not l.startswith('source = '))
        out.append(b)
    return '\n[[package]]\n'.join(out)
print(commit,'committed',h(lock))
print(commit,'servil source dropped',h(drop_source('blake3-servil')))
print(commit,'clocks source dropped',h(drop_source('clocks')))
blocks=drop_source('blake3-servil').split('\n[[package]]\n')
print(commit,'both dropped',h(drop_source('clocks')))
