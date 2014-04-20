compile:
	gcc -shared -fPIC -ldl fake-uname.c -o fake-uname.so

packer:
	packer build debian64_wheezy.json
