FROM centos:centos7
ADD . /srv
WORKDIR /srv
RUN yum install -y ruby ruby-devel rubygem-bundler postgresql-devel gcc make openssl-devel gcc-c++ mysql-devel libxml2-devel libxslt-devel
RUN bundle install
EXPOSE 8080
CMD ["bundle", "exec", "unicorn", "-l", "0.0.0.0:8080", "-c", "config/unicorn.rb"]
