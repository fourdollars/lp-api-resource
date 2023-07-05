 [![GitHub: fourdollars/lp-api-resource](https://img.shields.io/badge/GitHub-fourdollars%2Flp%E2%80%90api%E2%80%90resource-darkgreen.svg)](https://github.com/fourdollars/lp-api-resource/) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT) [![Bash](https://img.shields.io/badge/Language-Bash-red.svg)](https://www.gnu.org/software/bash/) ![Docker](https://github.com/fourdollars/lp-api-resource/workflows/Docker/badge.svg) [![Docker Pulls](https://img.shields.io/docker/pulls/fourdollars/lp-api-resource.svg)](https://hub.docker.com/r/fourdollars/lp-api-resource/)
# lp-api-resource
[concourse-ci](https://concourse-ci.org/)'s lp-api-resource to interact with https://api.launchpad.net/ by using https://github.com/fourdollars/lp-api.

## Config 

### Resource Type

```yaml
resource_types:
- name: lp-api
  type: registry-image
  source:
    repository: fourdollars/lp-api-resource
  defaults:
    oauth_consumer_key: test
    oauth_token: csjrGznX4Jq59CB8941N
    oauth_token_secret: wxDNqsCLxzrmhb2K27FRGjc7hdp3zQk0b4N8cnfRzVHnJfCFlHgkGHxDk5qMPTSdQFSsllS4dwGBD18Q
```

or

```yaml
resource_types:
- name: lp-api
  type: registry-image
  source:
    repository: ghcr.io/fourdollars/lp-api-resource
  defaults:
    oauth_consumer_key: test
    oauth_token: csjrGznX4Jq59CB8941N
    oauth_token_secret: wxDNqsCLxzrmhb2K27FRGjc7hdp3zQk0b4N8cnfRzVHnJfCFlHgkGHxDk5qMPTSdQFSsllS4dwGBD18Q
```

### Resource

* oauth_consumer_key: **optional**, choose what you like.
* oauth_token: **optional**, run `lp-api -key oauth_consumer_key` to get it in ~/.config/lp-api.toml.
* oauth_token_secret: **optional**, run `lp-api -key oauth_consumer_key` to get it in ~/.config/lp-api.toml.

You need to export the proper payload content variable to make it work. https://concourse-ci.org/implementing-resource-types.html

### check step

* check: inline script (via source)

```yaml
resources:
- name: bug
  icon: bug-outline
  type: lp-api
  source:
    check: |
      #!/bin/bash
      set -exuo pipefail
      IFS=$'\n\t'
      lp-api get bugs/123 > payload.json
      digest=$(jq -S -M < payload.json | sha256sum | awk '{print $1}')
      payload=$(cat <<ENDLINE
        [
          {
            "digest": "sha256:${digest}"
          }
        ]
      ENDLINE
      )
      export payload
```

### get step

* get: inline script (via source or params)

```yaml
resources:
- name: bug
  icon: bug-outline
  type: lp-api
  check_every: 10m
  source:
    get: |
      #!/bin/bash
      set -exuo pipefail
      IFS=$'\n\t'
      lp-api get bugs/123 > payload.json
      digest=$(jq -S -M < payload.json | sha256sum | awk '{print $1}')
      payload=$(cat <<ENDLINE
      {
        "version": {
          "digest": "sha256:${digest}"
        },
        "metadata": [
          {
            "name": "Bug #$(jq -r .id < payload.json)",
            "value": "$(jq -r .title < payload.json | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')"
          }
        ]
      }
      ENDLINE
      )
      export payload
```

### put step

You need to provide one of them at least.

* put: inline script (via source or params)
* script: script file (via params)

```yaml
resources:
- name: bug
  icon: bug-outline
  type: lp-api
  check_every: 10m
  source:
    put: |
      #!/bin/bash
      set -exuo pipefail
      IFS=$'\n\t'
      lp-api post bugs/123 ws.op=newMessage content="New comment"
      lp-api get bugs/123 > payload.json
      digest=$(jq -S -M < payload.json | sha256sum | awk '{print $1}')
      payload=$(cat <<ENDLINE
      {
        "version": {
          "digest": "sha256:${digest}"
        },
        "metadata": [
          {
            "name": "Bug #$(jq -r .id < payload.json)",
            "value": "$(jq -r .title < payload.json | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')"
          }
        ]
      }
      ENDLINE
      )
      export payload
```

or

```yaml
jobs:
- name: check-bug
  plan:
  - get: bug
    timeout: 1m
  - task: check
    timeout: 1m
    config:
      platform: linux
      image_resource:
        type: registry-image
        source:
          repository: fourdollars/lp-api-resource
      outputs:
        - name: comment
      run:
        path: bash
        args:
        - -exc
        - |
          mkdir -p comment
          echo "Another comment" > comment/comment.log
  - put: bug
    timeout: 1m
    params:
      put: |
        #!/bin/bash
        set -exuo pipefail
        IFS=$'\n\t'
        COMMENT=$(cat comment/comment.log)
        lp-api post bugs/123 ws.op=newMessage content="$COMMENT"
        lp-api get bugs/123 > payload.json
        digest=$(jq -S -M < payload.json | sha256sum | awk '{print $1}')
        payload=$(cat <<ENDLINE
        {
          "version": {
            "digest": "sha256:${digest}"
          },
          "metadata": [
            {
              "name": "Bug #$(jq -r .id < payload.json)",
              "value": "$(jq -r .title < payload.json | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')"
            }
          ]
        }
        ENDLINE
        )
        export payload
```

or

```yaml
jobs:
- name: check-bug
  plan:
  - get: bug
    timeout: 1m
  - task: check
    timeout: 1m
    config:
      platform: linux
      image_resource:
        type: registry-image
        source:
          repository: fourdollars/lp-api-resource
      outputs:
        - name: comment
      run:
        path: bash
        args:
        - -exc
        - |
          mkdir -p comment
          echo "Another comment" > comment/comment.log
  - get: some-script-repo
  - put: bug
    timeout: 1m
    params:
      script: some-script-repo/comment.sh
```
