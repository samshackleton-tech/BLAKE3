import csv,sys,os
root=sys.argv[1]
for d in ['base-16','base-32','base-48','fix-16','fix-32','fix-48']:
    v={}
    for row in csv.reader(open(os.path.join(root,d,'stat.csv'))):
        if len(row)>3 and row[0].replace('.','').isdigit(): v[row[2]]=float(row[0])
    ins=v.get('instructions',1)
    print(d, ' '.join(f"{k.split('.')[-1]}={v[k]/ins*1000:.2f}/ki" for k in v if k not in('instructions','cycles')), f"ipc={ins/v['cycles']:.2f}")
