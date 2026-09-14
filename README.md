# Tstat RRD Viewer

A simple CGI tool (based on the classic `drraw`-style Tstat web interface)
and a Docker image to visualize [Tstat](http://tstat.polito.it/) RRD files
over the web.

## What's in here

- [`cgi-bin/tstat_rrd.cgi`](cgi-bin/tstat_rrd.cgi) — the Perl CGI page that
  reads the RRD files and renders the graphs.
- `Dockerfile` / [`docker/`](docker) — builds an image running nginx +
  fcgiwrap + the CGI script, exposed on port 80 at `/tstat_rrd.cgi`.
- [`rrd-example/`](rrd-example) — a sample set of Tstat RRD files you can
  use to try everything out locally.

## Configuration: which folders to show

The CGI looks for traces under a single root directory,
`/var/www/tstat/rrd_data` inside the container. Every sub-directory that
contains `*.rrd` files is automatically picked up and offered as a
selectable trace in the web UI — you don't need to edit any config file,
just mount the folders you want to expose:

```bash
docker run -d -p 8080:80 \
  -v /path/to/probe1:/var/www/tstat/rrd_data/probe1:ro \
  -v /path/to/probe2:/var/www/tstat/rrd_data/probe2:ro \
  tstat-rrd-viewer
```

or, with `docker-compose.yml` (see the provided example, already wired to
`rrd-example/`):

```yaml
volumes:
  - /path/to/probe1:/var/www/tstat/rrd_data/probe1:ro
  - /path/to/probe2:/var/www/tstat/rrd_data/probe2:ro
```

Each mounted folder should look like `rrd-example/`: a flat directory of
`<variable>.rrd` (or `<variable>.idxN.rrd`) files produced by Tstat for one
probe/trace.

## Optional password protection

Password protection is handled by nginx (HTTP Basic Auth), not the CGI
script itself. It is **off by default**. To turn it on, set two
environment variables when running the container:

```bash
docker run -d -p 8080:80 \
  -e BASIC_AUTH_USER=admin \
  -e BASIC_AUTH_PASS=change-me \
  -v /path/to/probe1:/var/www/tstat/rrd_data/probe1:ro \
  tstat-rrd-viewer
```

If either variable is unset/empty, the site is served without
authentication.

## Build & run

```bash
docker build -t tstat-rrd-viewer .
docker compose up --build
```

Then open <http://localhost:8080/tstat_rrd.cgi> (or `/` which redirects to
it). With the default `docker-compose.yml`, the bundled `rrd-example/` data
set is mounted as the `example` trace so you can confirm graphs render
correctly out of the box.

## Notes on the CGI script

- Password protection is now a single optional HTTP Basic Auth layer in
  nginx for the whole site, rather than a separate data directory.
- The script `chdir`s into its own directory at startup, so the
  relative `rrd_data` / `rrd_images` / `rrd_gallery` paths resolve
  correctly no matter how the FastCGI wrapper invokes it (those paths can
  still be overridden with the `RRD_DATA_DIR`, `RRD_IMG_DIR` and
  `RRD_GALLERY_DIR` environment variables if needed).
- Removed a hardcoded check that hid a few extra features (EPS download,
  "add to gallery") from anyone outside the original `polito.it` network —
  access control is now solely the optional Basic Auth above.
- Fixed a small JS typo (`windod.focus` → `newwindow.focus`) in the
  "add to gallery" popup.
