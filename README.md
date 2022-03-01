# OpenSAFELY Backends


This site allows us to host a public holding page for our private backends.
This enables use to authenticate and maintain TLS certificates using
LetsEncrypt that we can then re-use in our various secure backend services,
which are not publically routable.

It is deployed as dokku app called `backends`, and it serves a single static
html page on multiple `*.backends.opensafely.org` domains. We have configured
LetsEncrypt to reuse the same key, so that we do not have to update the key on
every backend every 2-3 months.


## LetsEncrypt client

Sadly we cannot use the dokku letsencrypt plugin, as it does not support
reusing the private key when renewing certificates.

Instead we use the default certbot ACME client packaged with debian to manage
the registration and renewal. We then use a custom post-renewal hook to load
the new certificates into the dokku config for this app.

As of 2022-02-24, we create a certificate to explicitly serve the following
domains:

* backends.opensafely.org
* tpp.backends.opensafely.org
* emis.backends.opensafely.org

Note: we could in theory have a wildcard certificate for
`*.backends.opensafely.org`, but this requires ACME DNS challenges, which
in turn require a very privileged Cloudflare API token, and also need a newer
version of certbot than is currently available on dokku2.


## Adding new domain for a new backend

There is a wildcard DNS for `*.backends.opensafely.org` set up in cloudflare, so no new DNS needed.

To add a new subdomain for a new backend, run these commands on dokku2:

1) Add the domain to the dokku application:

    dokku domains:add backends NEWBACKEND.backends.opensafely.org

2) Request a new certificate that includes *all* the domains, and has all the correct renewal options:

    sudo certbot certonly --nginx --reuse-key --post-hook /root/copy-dokku-certs.sh $(dokku domains:report backends | egrep -o '[a-z]*\.?backends.opensafely.org' | sed 's/^/-d /' | tr -d '\n')

The post-hook should run and import the new certificate into dokku. You should
be able to check your new domain is working by going to:

https://NEWBACKEND.backends.opensafely.org

3) Update the domain list above in this README


## Upload in the certificate to the secure backend

The cert and private key are located at:

    /etc/letsencrypt/live/backends.opensafely.org/fullchain.pem
    /etc/letsencrypt/live/backends.opensafely.org/privkey.pem

These need to be securely copied up to the new backend to get it set up
intially. The backend will take care of keeping up to date with the certificate
as it is renewed

## Deploying the static holding page

This is only needed if want to update the index.html page.

If you haven't already, you'll need to add your key to the dokku user's list of
allowed ssh-keys. On dokku2, run:

    cat ~/.ssh/authorized_keys | sudo dokku ssh-keys:add admin

Then, back in your local checkout, add dokku as remote and push:

    git remote add dokku dokku@dokku2.ebmdatalab.net:backends
    git push dokku main

Note: this is not automated, as is a very infrequent task.


## Dokku2 certbot configuration


The configuration for this certificate should live at:


    /etc/letsencrypt/renewal/backends.opensafely.org


This contains various configuration parameters for renewing the certificate.

The post-hook script lives at /root/copy-dokku-certs.sh. A copy is kept in the
repository too. The path to this file can be change by editing the above file
if needed.
