#!/usr/bin/env bash
set -u
cd /f/诡异事务局
TOKEN=$(cat _setup/.gh_token2)
API="https://api.github.com"
P="--proxy http://127.0.0.1:7897"

create() {
  local name="$1" desc="$2"
  local body="{\"name\":\"$name\",\"description\":\"$desc\",\"private\":false,\"has_wiki\":false}"
  local code
  code=$(curl -sS -m 40 $P -o "/tmp/mk_$name.json" -w "%{http_code}" -X POST \
    -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github+json" \
    "$API/user/repos" -d "$body")
  echo "== $name HTTP $code"
  grep -o '"full_name": "[^"]*"' "/tmp/mk_$name.json" || head -c 200 "/tmp/mk_$name.json"
  echo
}

create anomaly-bureau-docs "诡异事务局 — 剧本、世界观圣经、Codex 交接文档与 Web 原型页面"
create anomaly-bureau-game "诡异事务局 · 第一季「补丁」— Godot 4.7 主工程（岚桥站 0017 序章 / 便利店 / 铁路）"
