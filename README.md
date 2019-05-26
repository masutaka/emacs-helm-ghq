# helm-ghq.el

[![melpa badge][melpa-badge]][melpa-link]
[![melpa stable badge][melpa-stable-badge]][melpa-stable-link]

[melpa-link]: https://melpa.org/#/helm-ghq
[melpa-stable-link]: https://stable.melpa.org/#/helm-ghq
[melpa-badge]: https://melpa.org/packages/helm-ghq-badge.svg
[melpa-stable-badge]: https://stable.melpa.org/packages/helm-ghq-badge.svg

## Introduction

`helm-ghq.el` provides interfaces of [ghq](https://github.com/motemen/ghq) with helm.

## Screenshot

![helm-ghq](image/helm-ghq.png)

## Requirements

* Emacs 24.5 or higher
* helm 1.8.0 or higher
* [ghq](https://github.com/motemen/ghq) 0.7.1 or higher.

## Installation

You can install `helm-ghq.el` from [MELPA](https://melpa.org) with package.el (`M-x package-install helm-ghq`).

## Usage

### `helm-ghq`

Execute with `ghq list --full-path` command. You can select a
directory from the results.

### `helm-for-files`

Require the following configuration.

```lisp
(add-to-list 'helm-for-files-preferred-list 'helm-ghq-source)
```
