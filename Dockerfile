ARG VERSION=latest
ARG ODOO_IMAGE=odoo:${VERSION}
FROM ${ODOO_IMAGE}
ARG VERSION
LABEL maintainer="Poonlap V. <poonlap@tanabutr.co.th>"

USER root
    
# Generate locale, set timezone
RUN apt-get update \
	&& apt-get -yq install locales tzdata git curl fonts-tlwg-laksaman gcc libpython3-dev\
	&& sed -i 's/# th_/th_/' /etc/locale.gen \
	&& locale-gen \
    && cp /usr/share/zoneinfo/Asia/Bangkok /etc/localtime

# Add Odoo Repository for upgrading and commit the image
RUN curl https://nightly.odoo.com/odoo.key | apt-key add -
RUN if [ ${VERSION} = 'latest' ]; then echo "deb http://nightly.odoo.com/14.0/nightly/deb/ ./" >> /etc/apt/sources.list.d/odoo.list; else \
       echo "deb http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/ ./" >> /etc/apt/sources.list.d/odoo.list; fi

# Add OCA modules via git
# ODOO_VERSION variable is inherited from odoo official image
RUN mkdir -p /opt/odoo/addons \ 
	&& cd /opt/odoo/addons \
	&& if [ ${VERSION} = 12.0 ]; then git clone --single-branch --branch ${ODOO_VERSION} https://github.com/OCA/server-tools.git; \
	   git clone --single-branch --branch ${ODOO_VERSION} https://github.com/OCA/server-ux.git; \
	   git clone --single-branch --branch ${ODOO_VERSION} https://github.com/OCA/reporting-engine.git; fi \
    && git clone --single-branch --branch ${ODOO_VERSION} https://github.com/OCA/web.git || git clone --single-branch --branch 13.0 https://github.com/OCA/web.git\
	&& git clone --single-branch --branch ${ODOO_VERSION} https://github.com/OCA/partner-contact.git || git clone --single-branch --branch 13.0 https://github.com/OCA/partner-contact.git\
	&& git clone --single-branch --branch ${ODOO_VERSION} https://github.com/OCA/server-ux.git || git clone --single-branch --branch 13.0 https://github.com/OCA/server-ux.git\
	&& git clone --single-branch --branch ${ODOO_VERSION} https://github.com/OCA/server-brand.git || git clone --single-branch --branch 13.0 https://github.com/OCA/server-brand.git\
	&& git clone --single-branch --branch ${ODOO_VERSION} https://github.com/OCA/social.git || git clone --single-branch --branch 13.0 https://github.com/OCA/social.git\
	&& git clone --single-branch --branch ${ODOO_VERSION} https://github.com/OCA/account-financial-reporting  || git clone --single-branch --branch 13.0 https://github.com/OCA/account-financial-reporting \
	&& git clone --single-branch --branch ${ODOO_VERSION} https://github.com/OCA/reporting-engine.git || git clone --single-branch --branch 13.0 https://github.com/OCA/reporting-engine.git

RUN pip3 install num2words xlwt xlrd openpyxl promptpay --no-cache-dir 

# Upgrade Odoo to the latest 13.0 nightly build when VERSION=13.0 (the current docker odoo official)
# Upgrade Odoo to 14.0 nightly build when VERSION=latest (master/nightly)
RUN apt-get update \
	&& apt-get -yq upgrade odoo; 

COPY ./odoo-12.0.conf ./odoo.conf /etc/odoo/
RUN if [ ${VERSION} = 12.0 ]; then mv -v /etc/odoo/odoo-12.0.conf /etc/odoo/odoo.conf; fi \
	&& chown odoo /etc/odoo/odoo.conf

USER odoo
