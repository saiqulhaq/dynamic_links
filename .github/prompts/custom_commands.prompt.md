---
mode: agent
---

this project is based on this repo https://github.com/nickjj/docker-rails-example.
It is an Rails app that provides docker compose setup.
Following is the README content of the project:

<readme>
### Back-end

- [PostgreSQL](https://www.postgresql.org/)
- [Redis](https://redis.io/)
- [Sidekiq](https://github.com/mperham/sidekiq)
- [Action Cable](https://guides.rubyonrails.org/action_cable_overview.html)
- [ERB](https://guides.rubyonrails.org/layouts_and_rendering.html)

### Front-end

- [esbuild](https://esbuild.github.io/)
- [Hotwire Turbo](https://hotwired.dev/)
- [StimulusJS](https://stimulus.hotwired.dev/)
- [TailwindCSS](https://tailwindcss.com/)
- [Heroicons](https://heroicons.com/)

## 🍣 Notable opinions and packages

Here's a run down on what's different. You can also use this as a guide to
Dockerize an existing Rails app.

- **Core**:
  - Use PostgreSQL (`-d postgresql)` as the primary SQL database
  - Use Redis as the cache back-end
  - Use Sidekiq as a background worker through Active Job
  - Use a standalone Action Cable process
  - Remove `solid_*` adapters (for now)
  - Remove Kamal and Thruster (for now)
- **App Features**:
  - Add `pages` controller with a home page
  - Add `up` controller with 2 health check related actions
  - Remove generated code around PWA and service workers
- **Config**:
  - Log to STDOUT so that Docker can consume and deal with log output
  - Credentials are removed (secrets are loaded in with an `.env` file)
  - Extract a bunch of configuration settings into environment variables
  - Rewrite `config/database.yml` to use environment variables
  - `.yarnc` sets a custom `node_modules/` directory
  - `config/initializers/enable_yjit.rb` to enable YJIT
  - `config/initializers/rack_mini_profiler.rb` to enable profiling Hotwire Turbo Drive
  - `config/routes.rb` has Sidekiq's dashboard ready to be used but commented out for safety
  - `Procfile.dev` has been removed since Docker Compose handles this for us
  - Brakeman has been removed
- **Assets**:
  - Use esbuild (`-j esbuild`) and TailwindCSS (`-c tailwind`)
  - Add `postcss-import` support for `tailwindcss` by using the `--postcss` flag
  - Add ActiveStorage JavaScript package
  - Add [Hotwire Spark](https://github.com/hotwired/spark) for live reloading in development
- **Public:**
  - Custom `502.html` and `maintenance.html` pages
  - Generate favicons using modern best practices

Besides the Rails app itself, a number of new Docker related files were added
to the project which would be any file having `*docker*` in its name. Also
GitHub Actions have been set up.

## 🚀 Running this app

#### Copy an example .env file because the real one is git ignored:

```sh
cp .env.example .env
```

#### Build everything:

```sh
docker compose up --build
```

#### Setup the initial database:

```sh
# You can run this from a 2nd terminal.
./run rails db:setup
```

_We'll go over that `./run` script in a bit!_

#### Check it out in a browser:

Visit <http://localhost:8000> in your favorite browser.

#### Formatting the code base:

```sh
# You should see that everything is unchanged (it's all already formatted).
./run format
```

You can also run `./run format --autocorrect` which will automatically correct
any issues that are auto-correctable. Alternatively the shorthand `-a` flag
does the same thing.

_There's also a `./run quality` command to lint and format all files._

#### Running the test suite:

```sh
# You can run this from the same terminal as before.
./run test
```

You can also run `./run test -b` with does the same thing but builds your JS
and CSS bundles. This could come in handy in fresh environments such as CI
where your assets haven't changed and you haven't visited the page in a
browser.

#### Stopping everything:

```sh
# Stop the containers and remove a few Docker related resources associated to this project.
docker compose down
```

#### Sanity check to make sure the tests still pass:

It's always a good idea to make sure things are in a working state before
adding custom changes.

```sh
# You can run this from the same terminal as before.
./run quality
./run test
```

## 🛠 Updating dependencies

You can run `./run bundle:outdated` or `./run yarn:outdated` to get a list of
outdated dependencies based on what you currently have installed. Once you've
figured out what you want to update, go make those updates in your `Gemfile`
and / or `package.json` file.

Or, let's say you've customized your app and it's time to add a new dependency,
either for Ruby or Node.

#### In development:

##### Option 1

1. Directly edit `Gemfile` or `package.json` to add your package
2. `./run deps:install` or `./run deps:install --no-build`
   - The `--no-build` option will only write out a new lock file without re-building your image

##### Option 2

1. Run `./run bundle add mypackage --skip-install` or `run yarn add mypackage --no-lockfile` which will update your `Gemfile` or `package.json` with the latest version of that package but not install it
2. The same step as step 2 from option 1

Either option is fine, it's up to you based on what's more convenient at the
time. You can modify the above workflows for updating an existing package or
removing one as well.

You can also access `bundle` and `yarn` in Docker with `./run bundle` and
`./run yarn` after you've upped the project.

#### In CI:

You'll want to run `docker compose build` since it will use any existing lock
files if they exist. You can also check out the complete CI test pipeline in
the [run](https://github.com/nickjj/docker-rails-example/blob/main/run) file
under the `ci:test` function.
</readme>
