FROM ubuntu:24.04

ARG RUBY_VERSION=4.0.5
# Ruby's ABI version — .bundle/ruby/<ABI> and gem dirs use this, not the patch version
ARG RUBY_ABI=4.0.0

### base ###
ENV DEBIAN_FRONTEND=noninteractive LANG=en_US.UTF-8
# noble ships minimized with unminimize as a separate package; restore man pages
# for students, then drop the tool. graphviz unpinned (focal pin doesn't exist here).
# t64 suffixes are noble's 64-bit time_t renames of the chrome-headless-shell libs.
# No redis-server or postgresql server: docker-compose provides both services;
# the image only needs psql (postgresql-client-18, from pgdg) and libpq-dev.
# Ruby build deps (libyaml-dev etc.) are explicit because mise compiles from source
# without RVM's `rvm requirements` step.
RUN apt-get update \
    && apt-get install -yq unminimize && (yes | unminimize) \
    && apt-get install -yq \
        curl \
        wget \
        man-db \
        acl \
        zip \
        unzip \
        bash-completion \
        build-essential \
        jq \
        locales \
        libpq-dev \
        sudo \
        git \
        graphviz \
        psmisc \
        libssl-dev \
        libyaml-dev \
        libreadline-dev \
        zlib1g-dev \
        libffi-dev \
        libgmp-dev \
        libasound2t64 \
        libatk-bridge2.0-0t64 \
        libatk1.0-0t64 \
        libatspi2.0-0t64 \
        libgbm1 \
        libnspr4 \
        libnss3 \
        libxcomposite1 \
        libxdamage1 \
        libxfixes3 \
        libxkbcommon0 \
        libxrandr2 \
    && install -d /usr/share/postgresql-common/pgdg \
    && curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
    && echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt noble-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -yq postgresql-client-18 nodejs gh \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && locale-gen en_US.UTF-8 \
    && apt-get purge -yq unminimize \
    && apt-get autoremove -yq && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* \
    # Container user
    # '-l': see https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user
    && useradd -l -u 33334 -G sudo -md /home/student -s /bin/bash -p student student \
    # Passwordless sudo for users in the 'sudo' group
    && sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers
ENV HOME=/home/student

### Student user ###
USER student
# Use sudo so that user does not get sudo usage info on (the first) login
RUN sudo mkdir -p $HOME \
    && sudo echo "Running 'sudo' for container: success" && \
    # Create .bashrc.d folder and source it in the bashrc
    mkdir /home/student/.bashrc.d && \
    (echo; echo "for i in \$(ls \$HOME/.bashrc.d/*); do source \$i; done"; echo) >> /home/student/.bashrc \
    # Install Ruby with mise (replaces RVM; compiles from source like RVM did)
    && curl -fsSL https://mise.run | sh \
    && /home/student/.local/bin/mise install ruby@${RUBY_VERSION} \
    && /home/student/.local/bin/mise use --global ruby@${RUBY_VERSION} \
    && bash -c 'eval "$(/home/student/.local/bin/mise activate bash --shims)" && gem install bundler --no-document' \
    # Drop compile-time caches/sources (same spirit as the old rvm src/archives cleanup)
    && rm -rf /home/student/.local/share/mise/downloads /home/student/.cache \
    && echo 'eval "$(/home/student/.local/bin/mise activate bash)"' >> /home/student/.bashrc.d/70-ruby

# Same path layout contract as the RVM image: /home/student/.bundle/ruby/<ABI>
# comes first so project gems win; GEM_HOME is single-entry (the old colon-joined
# GEM_HOME confused bundler in non-login shells).
ENV MISE_RUBY=/home/student/.local/share/mise/installs/ruby/4.0.5
ENV GEM_HOME=${MISE_RUBY}/lib/ruby/gems/${RUBY_ABI} \
    GEM_PATH=/home/student/.bundle/ruby/${RUBY_ABI}:${MISE_RUBY}/lib/ruby/gems/${RUBY_ABI} \
    PATH=/home/student/.bundle/ruby/${RUBY_ABI}/bin:${MISE_RUBY}/lib/ruby/gems/${RUBY_ABI}/bin:${MISE_RUBY}/bin:/home/student/.local/share/mise/shims:/home/student/.local/bin:$PATH

WORKDIR /rails-template

# Pre-install gems into /rails-template/gems/
COPY --chown=student:student Gemfile Gemfile.lock /rails-template/
RUN /bin/bash -l -c "bundle config set --local path '/home/student/.bundle' && bundle install" \
    # Remove rdoc's RubyGems plugin from BUNDLE_PATH to prevent duplicate loading.
    # rdoc is already a Ruby default gem; having a second copy in BUNDLE_PATH (via GEM_PATH)
    # causes constant redefinition warnings during 'gem install'. The gem dir + spec stay
    # so bundler considers it installed and won't reinstall at Codespace startup.
    && rm -f /home/student/.bundle/ruby/${RUBY_ABI}/plugins/rdoc_plugin.rb \
    && rm -f /home/student/.bundle/ruby/${RUBY_ABI}/gems/rdoc-*/lib/rubygems_plugin.rb

RUN sudo wget -qO ./prompt "https://gist.githubusercontent.com/jelaniwoods/7e5db8d72b3dfac257b7eb562cfebf11/raw/af43083d91c0eb1489059a2ad9c39474a34ddbda/thoughtbot-style-prompt" \
    && /bin/bash -l -c "cat ./prompt >> ~/.bashrc" \
    # Set git config
    && git config --global push.default upstream \
    && git config --global merge.ff only \
    && git config --global alias.aa '!git add -A' \
    && git config --global alias.cm '!f(){ git commit -m "${*}"; };f' \
    && git config --global alias.acm '!f(){ git add -A && git commit -am "${*}"; };f' \
    && git config --global alias.as '!git add -A && git stash' \
    && git config --global alias.p 'push' \
    && git config --global alias.sla 'log --oneline --decorate --graph --all' \
    && git config --global alias.co 'checkout' \
    && git config --global alias.cob 'checkout -b' \
    && git config --global --add --bool push.autoSetupRemote true \
    && git config --global core.editor "code --wait" \
    # Add g alias for git status
    && echo "# No arguments: 'git status'\n\
# With arguments: acts like 'git'\n\
g() {\n\
  if [[ \$# > 0 ]]; then\n\
    git \$@\n\
  else\n\
    git status\n\
  fi\n\
}\n# Complete g like git\n\
source /usr/share/bash-completion/completions/git\n\
__git_complete g __git_main" >> ~/.bash_aliases \
    # Add other aliases
    && echo "alias be='bundle exec'" >> ~/.bash_aliases \
    && echo "alias rspec='bundle exec rspec'" >> ~/.bash_aliases \
    && echo "alias rubocop='bundle exec rubocop'" >> ~/.bash_aliases \
    && echo "alias grade='rake grade'" >> ~/.bash_aliases \
    && echo "alias grade:reset_token='rake grade:reset_token'" >> ~/.bash_aliases \
    && echo 'export PATH="$PWD/bin:/home/student/.bundle/ruby/4.0.0/bin:$PATH"' >> ~/.bashrc \
    && echo "# Configure bundler and mise-ruby paths" >> ~/.bashrc \
    && echo 'export BUNDLE_PATH="/home/student/.bundle"' >> ~/.bashrc \
    && echo 'export GEM_HOME="/home/student/.local/share/mise/installs/ruby/4.0.5/lib/ruby/gems/4.0.0"' >> ~/.bashrc \
    && echo 'export GEM_PATH="/home/student/.bundle/ruby/4.0.0:/home/student/.local/share/mise/installs/ruby/4.0.5/lib/ruby/gems/4.0.0"' >> ~/.bashrc
