#!/usr/bin/env bats

load test_helper

setup() {
  mkdir -p "${RBENV_TEST_DIR}/myproject"
  cd "${RBENV_TEST_DIR}/myproject"
}

@test "fails without arguments" {
  run rbenv-version-file-read
  assert_failure ""
}

@test "fails for invalid file" {
  run rbenv-version-file-read "non-existent"
  assert_failure ""
}

@test "fails for blank file" {
  echo > my-version
  run rbenv-version-file-read my-version
  assert_failure ""
}

@test "reads simple version file" {
  cat > my-version <<<"1.9.3"
  run rbenv-version-file-read my-version
  assert_success "1.9.3"
}

@test "ignores leading spaces" {
  cat > my-version <<<"  1.9.3"
  run rbenv-version-file-read my-version
  assert_success "1.9.3"
}

@test "reads only the first word from file" {
  cat > my-version <<<"1.9.3-p194@tag 1.8.7 hi"
  run rbenv-version-file-read my-version
  assert_success "1.9.3-p194@tag"
}

@test "loads only the first line in file" {
  cat > my-version <<IN
1.8.7 one
1.9.3 two
IN
  run rbenv-version-file-read my-version
  assert_success "1.8.7"
}

@test "ignores leading blank lines" {
  cat > my-version <<IN

1.9.3
IN
  run rbenv-version-file-read my-version
  assert_success "1.9.3"
}

@test "handles the file with no trailing newline" {
  echo -n "1.8.7" > my-version
  run rbenv-version-file-read my-version
  assert_success "1.8.7"
}

@test "ignores carriage returns" {
  cat > my-version <<< $'1.9.3\r'
  run rbenv-version-file-read my-version
  assert_success "1.9.3"
}

@test "prevents directory traversal" {
  cat > my-version <<<".."
  run rbenv-version-file-read my-version
  assert_failure "rbenv: invalid version in \`my-version'"

  cat > my-version <<<"../foo"
  run rbenv-version-file-read my-version
  assert_failure "rbenv: invalid version in \`my-version'"
}

@test "disallows path segments in version string" {
  cat > my-version <<<"foo/bar"
  run rbenv-version-file-read my-version
  assert_failure "rbenv: invalid version in \`my-version'"
}

@test "appends text from .ruby-variant file" {
  echo "2.6.3" > .ruby-version
  echo "jemalloc" > .ruby-variant

  run rbenv-version-file-read .ruby-version
  assert_success "2.6.3-jemalloc"

  rm .ruby-variant
  echo "jemalloc malloctrim" > .ruby-variant

  run rbenv-version-file-read .ruby-version
  assert_success "2.6.3-jemalloc"
}

@test "doesnt append .ruby-variant if .ruby-version contains variant" {
  echo "2.6.3-jemalloc" > .ruby-version
  echo "jemalloc" > .ruby-variant

  run rbenv-version-file-read .ruby-version
  assert_success "2.6.3-jemalloc"
}
