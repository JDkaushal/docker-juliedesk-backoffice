
FROM phusion/passenger-ruby22

# Set correct environment variables.
ENV HOME /root

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Run Bundle in a cache efficient way
WORKDIR /tmp  
ADD Gemfile /tmp/  
ADD Gemfile.lock /tmp/ 
RUN chown app /tmp/Gemfile.lock
RUN chmod +x /tmp/Gemfile.lock
RUN bash -lc 'rvm install ruby-2.2.0'
RUN bash -lc 'rvm --default use ruby-2.2.0'
RUN bash -lc 'rvm 2.2.0 do gem install bundler'

# Install ruby Requirements
USER app
RUN bash -lc 'bundle install'

USER root
# Start Nginx / Passenger
RUN rm -f /etc/service/nginx/down

# Remove the default site
RUN rm /etc/nginx/sites-enabled/default

# Add the nginx info
ADD juliedesk-backoffice.conf /etc/nginx/sites-enabled/juliedesk-backoffice.conf

# Prepare folders
RUN mkdir /home/app/juliedesk-backoffice

# Add the rails app
ADD . /home/app/juliedesk-backoffice

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*