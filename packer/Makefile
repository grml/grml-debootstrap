compile: fake-uname.so

fake-uname.so:
	gcc -shared -fPIC -ldl fake-uname.c -o fake-uname.so

packer: fake-uname.so
	packer build debian64_wheezy.json

.PHONY: compile packer
