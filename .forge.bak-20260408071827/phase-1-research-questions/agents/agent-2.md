# Agent 2: Binary Download Validation Best Practices

## Q1: Robust Methods to Validate a Downloaded Binary

### 1. HTTP Status Code Check (First Line of Defense)
Check the HTTP response code before trusting the file exists. A 404 page saved as `.exe` is ~2-10KB and passes `test -s`.

**Best approach:** Use curl's `--fail` flag or capture `%{http_code}` in write-out.

### 2. File Size Threshold
Compare file size against a known minimum. Platform binaries are rarely under 1MB.

```
# Minimum viable: reject anything under 100KB (102400 bytes)
stat --printf="%s" binary.exe  # Linux/macOS via stat
# Or: wc -c < binary.exe
```

Threshold guideline: reject if < 512KB for Go/Rust binaries; < 50KB for small utilities.

**Limitation:** An attacker-controlled server or a corrupt partial download can still pass. Use as a secondary check, not primary.

### 3. Magic Bytes (File Signature)
Every binary format starts with a known byte sequence:

| Format | Magic Bytes | Readable prefix |
|--------|-------------|-----------------|
| Windows PE (.exe) | `4D 5A` | `MZ` |
| ELF (Linux) | `7F 45 4C 46` | `\x7fELF` |
| Mach-O (macOS x64) | `CF FA ED FE` | (binary) |
| Mach-O (macOS arm64) | `CA FE BA BE` | (binary) |

**Check in Claude Code instructions:**
```
Read first 2 bytes of the downloaded file.
Windows: verify they are 4D 5A ("MZ").
Linux: verify they are 7F 45 4C 46 (ELF header).
If magic bytes do not match, the download is invalid — delete the file and abort.
```

Using `file` command (available on Linux/macOS):
```
file ./binary   # returns "ELF 64-bit LSB executable" or "PE32+ executable"
```
On Windows via PowerShell: `Format-Hex -Path .\binary.exe -Count 2`

### 4. Checksum Verification (Gold Standard)
If the release provides a SHA256 checksum file (e.g., `checksums.txt`):

```
# Download checksum file alongside binary
curl -fsSL https://releases.example.com/v1.0/checksums.txt -o checksums.txt
curl -fsSL https://releases.example.com/v1.0/binary-linux-amd64 -o binary

# Verify
sha256sum --check --ignore-missing checksums.txt
# or on macOS:
shasum -a 256 -c checksums.txt
```

**In Claude Code markdown instructions:** instruct to run `sha256sum` or `shasum -a 256` and compare against the published hash. Fail hard if mismatch.

**Limitation:** Requires the project to publish checksums. Not all tools do.

### 5. Combined Validation Sequence (Recommended for Claude Code skills)
Order checks from cheapest to most thorough:
1. HTTP status code — reject non-200
2. File size — reject < threshold
3. Magic bytes — reject wrong format
4. Checksum — verify if available

---

## Q2: Best curl Flag Combination for HTTP Error Detection

### `--fail` (short: `-f`)
Causes curl to exit with code 22 on HTTP 4xx/5xx. The file is NOT written on failure.

```
curl --fail --location --silent --show-error -o binary.exe https://example.com/binary.exe
```

- `--fail` (`-f`): exit non-zero on HTTP error, suppress error body
- `--location` (`-L`): follow redirects (GitHub releases redirect)
- `--silent` (`-s`): suppress progress meter
- `--show-error` (`-S`): still show error messages despite `-s`

**Important:** Without `-L`, GitHub release downloads always fail (they use redirects).

### `--fail-with-body`
Available in curl >= 7.76.0. Like `--fail` but still writes the body — useful for debugging but dangerous in production (the error HTML gets saved as the binary). Avoid for binary downloads.

### Capturing HTTP status code explicitly
```
HTTP_CODE=$(curl --location --silent --write-out "%{http_code}" -o binary.exe https://example.com/binary.exe)
if [ "$HTTP_CODE" != "200" ]; then
  echo "Download failed: HTTP $HTTP_CODE"
  rm -f binary.exe
  exit 1
fi
```

`-w "%{http_code}"` writes the status code to stdout separately from the body (which goes to `-o`). This works even if `--fail` is not used.

### Recommended flag set for Claude Code skill instructions:
```
curl --fail --location --silent --show-error --output <destination> <url>
```
Then check exit code: non-zero = download failed, delete file, abort with clear error.

### Additional useful flags:
- `--max-time 60` — timeout after 60 seconds (prevents hangs)
- `--retry 3 --retry-delay 2` — auto-retry on transient errors
- `--create-dirs` — create output directory if it doesn't exist

---

## Q3: `go install` as Fallback for Missing Platform Binaries

### How `go install` Works
`go install <module>@<version>` downloads, compiles, and installs a Go binary to `$GOPATH/bin` (default: `~/go/bin`). It always compiles from source for the current platform — no pre-built binary needed.

```
go install github.com/owner/tool@v1.2.3
go install github.com/owner/tool@latest
```

The binary lands at `$(go env GOPATH)/bin/tool` or `$(go env GOBIN)/tool`.

### When to Use as Fallback
Use when:
- Pre-built binary is unavailable for the current platform/arch combination
- The download URL returns 404
- Magic byte or checksum validation fails

### Fallback Decision Logic for Claude Code Skills

```
1. Detect OS and ARCH.
2. Construct download URL for pre-built binary.
3. Attempt: curl --fail -L -o <dest> <url>
4. If curl exits non-zero OR file size < threshold OR magic bytes wrong:
   a. Check if `go` is available: `go version`
   b. If Go available: run `go install <module>@<version>`
      - Binary will be at $(go env GOPATH)/bin/<name>
      - Copy or symlink to expected location
   c. If Go not available: instruct user to install Go or download manually.
5. Re-validate the binary after fallback install.
```

### Caveats
- Requires Go toolchain installed (not guaranteed on all machines)
- Compile time can be 30-120 seconds depending on module size
- `go install` respects `GOFLAGS`, `GOMODCACHE`, proxy settings
- Version must be exact tag (not a commit SHA) for reproducibility
- The resulting binary is always native to the current platform — no cross-compilation

### Checking for Go availability in skill instructions
```
If the command `go version` succeeds, Go is available.
Extract GOPATH with: go env GOPATH
The installed binary will be at: $(go env GOPATH)/bin/<tool-name>
```

---

## Summary: Recommended Validation Stack for Claude Code Markdown Skills

| Step | Check | Action on Failure |
|------|-------|-------------------|
| 1 | curl `--fail -L` exits 0 | Delete partial file, abort or try fallback |
| 2 | File size > 100KB | Delete file, abort or try fallback |
| 3 | Magic bytes match OS format | Delete file, abort or try fallback |
| 4 | Checksum matches (if available) | Delete file, abort — do not proceed |
| 5 | `go install` fallback | Only if curl unavailable for platform |

For markdown-based skill instructions (interpreted by Claude Code), prefer explicit conditional logic: "If X, then Y, else Z" over shell one-liners, since Claude executes these as reasoning steps rather than shell pipelines.
