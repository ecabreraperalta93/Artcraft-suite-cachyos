import tarfile, hashlib, os, glob, shutil
D=os.path.expanduser('~/artcraft-dist'); B=os.path.expanduser('~/artcraft-build/sfx')
files=sorted(glob.glob(D+'/*.pkg.tar.zst'))+[D+'/SHA256SUMS',D+'/instalar.sh',D+'/instalar-gui.sh',D+'/LEEME.txt']
with tarfile.open(B+'/payload.tar','w') as t:
    for f in files:
        ti=t.gettarinfo(f,'craft-suite/'+os.path.basename(f)); ti.uid=ti.gid=0; ti.uname=ti.gname='root'; ti.mode=0o755 if f.endswith('.sh') else 0o644
        with open(f,'rb') as fh: t.addfile(ti,fh)
h=hashlib.sha256()
with open(B+'/payload.tar','rb') as f:
    for b in iter(lambda: f.read(1<<20), b''): h.update(b)
sha=h.hexdigest()
hd=open(B+'/header.sh').read().replace('@@SHA256@@',sha).replace('@@OFFSET@@','0000000000'); n=len(hd.encode())
hd=hd.replace('PAYLOAD_OFFSET=0000000000','PAYLOAD_OFFSET=%010d'%n); assert len(hd.encode())==n
out=B+'/Instalar-Craft-Suite.run'
with open(out,'wb') as o:
    o.write(hd.encode())
    with open(B+'/payload.tar','rb') as f: shutil.copyfileobj(f,o,1<<20)
os.chmod(out,0o755); os.remove(B+'/payload.tar')
print('OK',os.path.getsize(out),'esperado',n+len(open(B+'/header.sh','rb').read())*0+ (os.path.getsize(out)-n),'sha',sha)
