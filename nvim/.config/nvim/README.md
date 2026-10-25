# NeoVim for Java development

This configuration turns NeoVim into a Java and Jakarta EE IDE for Maven and Gradle projects. It is not
tied to a specific project. Versions of Lombok, the code formatter and the JDK come from the project you
are working on, project specific settings live outside the project (see [Project settings](#project-settings)).

| Area | Tooling |
|------|---------|
| Language server | [jdtls](https://github.com/eclipse-jdtls/eclipse.jdt.ls) via [nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls) |
| Lombok, MapStruct | Lombok agent from the project, annotation processors from the build (m2e-apt) |
| Formatting | the project's [Spotless](https://github.com/diffplug/spotless) configuration, else jdtls |
| Build | Maven/Gradle tasks with [overseer.nvim](https://github.com/stevearc/overseer.nvim), errors go to the quickfix list |
| Run and debug | Tomcat runner, [nvim-dap](https://github.com/mfussenegger/nvim-dap) with hot code replace |
| Tests | [neotest](https://github.com/nvim-neotest/neotest) + [neotest-java](https://github.com/rcasia/neotest-java), jdtls test runner for debugging |
| Spring Boot | [spring-boot.nvim](https://github.com/JavaHello/spring-boot.nvim), only in projects that depend on Spring Boot |
| Jakarta Faces | Facelets highlighting, XML language server, `gd` from EL expressions to beans |
| JPA, databases | [vim-dadbod-ui](https://github.com/kristijanhusak/vim-dadbod-ui) with SQL completion |
| Git, reviews | [gitsigns](https://github.com/lewis6991/gitsigns.nvim), [fugitive](https://github.com/tpope/vim-fugitive), [diffview](https://github.com/dlyongemallo/diffview.nvim), `glab`/`gh` |

`<leader>` is the space key. Press it and wait to see all mappings in which-key.

## Prerequisites

- A JDK 21 or newer for jdtls. The newest installed LTS JDK is used, override it with the environment
  variable `JDTLS_JAVA_HOME`.
- The JDKs your projects need. They are detected in `/Library/Java/JavaVirtualMachines`,
  `~/Library/Java/JavaVirtualMachines`, `/usr/lib/jvm`, SDKMAN, mise, asdf and Homebrew and registered in
  jdtls, so each project compiles against the Java version its build declares.
- Maven or Gradle. A wrapper (`mvnw`, `gradlew`) in the project is preferred.
- `rg` ([ripgrep](https://github.com/BurntSushi/ripgrep)) for searching and the Facelets navigation.
- `glab` (GitLab) or `gh` (GitHub) for merge request reviews.
- A Tomcat installation if you want to run WAR projects, e.g. in `~/apps/apache-tomcat/`.

Mason installs the language servers and debug adapters on the first start (`:Mason` shows them):
`jdtls`, `java-debug-adapter`, `java-test`, `vscode-spring-boot-tools`, `lemminx`, `biome`.

Run once after the installation:

```vim
:NeotestJava setup
```

It downloads the JUnit console launcher that neotest-java uses to run tests.

## Opening a project

Start NeoVim in the project directory (`nvim` or `nvim .`). jdtls starts right away and imports the
project in the background, so search and navigation are ready when you open the first file. Opening a
Java file in any other way starts it too. Opening other files (e.g. a commit message) does not start it.

- **Project root**: the nearest directory with `mvnw`, `gradlew`, `.mvn` or `settings.gradle`, else the
  git root, else the topmost directory with a build file. All modules of a multi-module build share one
  jdtls instance.
- **Workspace**: jdtls keeps its index in `~/.cache/nvim/jdtls/workspaces/<project>-<hash>`. Each
  checkout (e.g. a git worktree per branch) gets its own workspace.
- **Lombok**: the version declared in the project (`lombok.version` or the Lombok dependency in the
  root or module `pom.xml`, or the Gradle build) is loaded from the local Maven or Gradle repository. If
  the project's Lombok is not downloaded yet or no version is declared, the Lombok bundled with jdtls is
  used. A notification tells you which one is active. Build the project once (`<leader>rp`) if it says
  "not downloaded yet".
- **Annotation processors** like MapStruct run inside jdtls as configured in the build
  (`annotationProcessorPaths`). Generated sources appear in `target/generated-sources/annotations`.
- **The project stays untouched**: the Eclipse metadata of jdtls (`.project`, `.classpath`,
  `.settings`) lives in the jdtls workspace, not in the project, and Eclipse launch configurations
  (`*.launch`) in the project are not rewritten.

The first import of a large project takes a few minutes. The progress is shown at the bottom right.
Memory for jdtls defaults to 6 GB, change it with `vim.g.jdtls_max_heap = "8g"` in
`lua/config/options.lua`.

## Navigating and editing

These mappings work in every language with a language server.

| Keys | Action |
|------|--------|
| `gd` | Go to definition (works for library classes, sources are downloaded or decompiled) |
| `gD` | Go to declaration |
| `gri` | Go to implementations |
| `grr` | Find references |
| `grt` | Go to type definition |
| `<leader>sc` | Search classes, methods and fields of the workspace, like "Go to symbol" in IntelliJ. Also works outside Java files once jdtls runs |
| `<leader>so` | Search the outline (symbols) of the current file, `gO` does the same |
| `K` | Documentation |
| `grn` | Rename |
| `gra` | Code actions: quick fixes, add import, create method, surround with try/catch, ... |
| `<leader>f` | Format the buffer |
| `<leader>th` | Toggle inlay hints (parameter names) |
| `<leader>sf` / `<leader>sg` | Search files / grep |
| `]d` / `[d` | Next / previous diagnostic, `<C-w>d` shows the message |
| `<leader>q` | Diagnostics in the location list, `<leader>sd` searches all diagnostics |

Java specific mappings (`<leader>J`):

| Keys | Action |
|------|--------|
| `<leader>Jg` | Generate code: getters/setters, constructors, `toString`, `equals`/`hashCode`, override methods |
| `<leader>Jo` | Organize imports |
| `<leader>Jv` | Extract variable (normal and visual mode) |
| `<leader>JC` | Extract constant (normal and visual mode) |
| `<leader>Jm` | Extract method (visual mode) |
| `<leader>Js` | Go to the super implementation |
| `<leader>Jt` / `<leader>JT` / `<leader>Jp` | Debug the nearest test method / the test class / a picked test |
| `<leader>Ju` | Update the project configuration after changing a `pom.xml` (usually automatic) |
| `<leader>Jb` | Rebuild the workspace |
| `<leader>Jr` | Restart jdtls |
| `<leader>Jw` | Delete the jdtls workspace of the project and restart (fixes a broken index) |
| `<leader>tl` | Toggle code lenses (reference and implementation counts) |

Commands from nvim-jdtls: `:JdtCompile`, `:JdtSetRuntime`, `:JdtBytecode` (javap), `:JdtJshell`,
`:JdtShowLogs`.

## Formatting

`<leader>f` formats the buffer with the project's own formatter:

- If the project configures **Spotless** (Maven or Gradle), Spotless formats the buffer through its IDE
  hook. This uses exactly the formatter, version and settings of the project (palantir-java-format,
  google-java-format, Eclipse, ...). The first run in a session takes a few seconds, the file on disk is
  not touched.
- Otherwise jdtls formats the buffer with its Eclipse formatter.

Java files are not formatted on save, so untouched code in legacy files stays as it is. Organize imports
on save is off for the same reason, use `<leader>Jo`.

## Run configurations, builds and tasks

Everything that runs in the background (builds, run configurations, servers, npm scripts) is an
[overseer](https://github.com/stevearc/overseer.nvim) task. Errors of the Java compiler are collected in
the quickfix list (`:copen`, `]q`/`[q`), it opens when a build fails.

| Keys | Action |
|------|--------|
| `<leader>rr` | Pick and run a run configuration or task (like "Run..." in IntelliJ) |
| `<leader>rl` | Run the last started task again (like "Rerun" in IntelliJ) |
| `<leader>rx` | Stop a running task |
| `<leader>ro` | Task list with output, `<CR>` on a task shows the actions |
| `<leader>ra` | Pick an action for a task (stop, restart, open output, ...) |
| `<leader>rm` | Build the current module and the modules it depends on (`install -pl <module> -am -DskipTests`) |
| `<leader>rp` | Build the whole project without tests |
| `<leader>rc` | Compile the current module |
| `<leader>rt` | Run the tests of the current module |
| `<leader>rT` | Run the tests of the current class with Maven/Gradle |
| `<leader>rs` | Edit the [project settings](#project-settings) |

`<leader>rr` offers:

- **Run configurations** of the project: your own from the project settings and the Maven and local
  Tomcat run configurations of IntelliJ (`.run/*.run.xml` and `.idea/workspace.xml`). IntelliJ
  configurations keep their goals, profiles, properties, environment, JDK, WAR, context path, ports and
  Tomcat installation, so they work in both editors.
- **Build tasks** for the current module or project (Maven or Gradle), and custom goals.
- npm/yarn scripts, make targets and other tasks overseer detects.

"Current module" is the module of the file in the current buffer. Tasks use the project's wrapper if
there is one. `:OverseerShell <command>` runs any shell command as a task.

### Run indicator

The right side of the statusline shows everything that runs, like the run widget of IntelliJ: servers
(󰒋), tasks (), a debug session ( running,  paused) and failed tasks (), until they are restarted or
removed from the task list. Click it to open the task list. Encoding and file format only appear when
they are not UTF-8 and Unix.

### Example: developing a plugin for a web application

A plugin is built with Maven and uploaded to a running server of the application. Start the server once
and run the upload after every change:

1. `<leader>ww` selects the server (e.g. the IntelliJ Tomcat configuration that deploys the
   application's WAR), `<leader>wd` starts it with the debugger.
2. `<leader>rr` runs the Maven run configuration that builds and uploads the plugin (e.g.
   `clean package plugin-deploy:upload -DdeployUrl=http://localhost:8090/app`).
3. After the next change, `<leader>rl` runs the upload again.

## Project settings

Settings that cannot be derived from the build are stored per project in
`~/.local/share/nvim/java-projects/<git remote>.json`. All checkouts of the same repository share them.
`:JavaSettings` (or `<leader>rs`) opens the file of the current project and creates it with defaults:

```json
{
  "build_args": [],
  "import_intellij": true,
  "jdk": null,
  "run_configurations": []
}
```

| Setting | Meaning |
|---------|---------|
| `jdk` | Major version of the JDK for the build tasks, e.g. `11`. `null` uses the project JDK of IntelliJ, else `$JAVA_HOME`. |
| `build_args` | Extra arguments for the build tasks (`<leader>rm`, `<leader>rp`, ...), e.g. `["-P", "dev"]`. |
| `import_intellij` | Offer the run configurations of IntelliJ. |
| `run_configurations` | Own run configurations, see below. They take precedence over IntelliJ configurations with the same name. |

A Maven run configuration:

| Field | Meaning |
|-------|---------|
| `name` | Name shown in the picker and the task list |
| `type` | `"maven"` |
| `args` | Goals and arguments, e.g. `["clean", "package", "-P", "dev"]` |
| `cwd` | Working directory, default: the project root |
| `env` | Environment variables |
| `jdk` | Major version of the JDK |

A Tomcat run configuration:

| Field | Meaning |
|-------|---------|
| `name` | Name shown in the picker and the task list |
| `type` | `"tomcat"` |
| `tomcat_home` | Tomcat installation (`CATALINA_HOME`) |
| `war_module` | Module that builds the exploded WAR, relative to the project root. Leave it out if the root builds it. |
| `war` | Alternatively a WAR file or an exploded WAR outside the project |
| `context_path` | Context path, default `/` |
| `http_port`, `debug_port` | Ports of Tomcat and of the debugger, default `8080` and `5005` |
| `jvm_args` | JVM arguments |
| `env` | Environment variables |
| `jdk` | Major version of the JDK |

`~` and `${root}` (the project root) are expanded in paths, arguments and environment variables.

Example with a server that deploys an external WAR, a server for the project's own WAR in development
mode and a Maven run configuration:

```json
{
  "run_configurations": [
    {
      "name": "App 8.5.6",
      "type": "tomcat",
      "tomcat_home": "~/apps/apache-tomcat/apache-tomcat-9.0.102",
      "war": "~/app-builds/8.5.6/app.war",
      "context_path": "/app",
      "http_port": 8090,
      "env": { "APP_CONFIG_DIR": "~/app/config" },
      "jdk": 11
    },
    {
      "name": "App from sources",
      "type": "tomcat",
      "tomcat_home": "~/apps/apache-tomcat/apache-tomcat-9.0.102",
      "war_module": "web-app",
      "context_path": "/main",
      "jvm_args": ["-Xmx4g", "-Dapp.dev_mode=true", "-Dapp.resource.path=${root}"],
      "jdk": 11
    },
    {
      "name": "Deploy plugin",
      "type": "maven",
      "args": ["clean", "package", "plugin-deploy:upload", "-DdeployUrl=http://localhost:8090/app"]
    }
  ]
}
```

## Running and debugging in Tomcat

Tomcat run configurations run as tasks. Each one gets its own Tomcat base directory in
`~/.cache/nvim/java-server/`, so one Tomcat installation serves all projects, branches and
configurations. An exploded WAR in the project is deployed without copying it.

The `<leader>w` mappings work with the selected server of the project, like the run configuration
selector in IntelliJ. The first use asks for it, `<leader>ww` changes it.

| Keys | Command | Action |
|------|---------|--------|
| `<leader>wd` | `:JavaServer debug` | Start the server with the debug port open and attach the debugger |
| `<leader>ws` | `:JavaServer start` | Start the server without debugger |
| `<leader>wx` | `:JavaServer stop` | Stop the server |
| `<leader>wb` | `:JavaServer build` | Build the exploded WAR (`package -DskipTests -pl <war_module> -am`) |
| `<leader>wr` | `:JavaServer rebuild` | Build the WAR, then restart the server with the debugger |
| `<leader>wa` | `:JavaServer attach` | Attach the debugger to the running server again |
| `<leader>wl` | `:JavaServer log` | Show the server output |
| `<leader>wo` | `:JavaServer open` | Open the application in the browser |
| `<leader>ww` | `:JavaServer select` | Select the server |

Starting a server that already runs restarts it. The debugger needs jdtls, which runs as soon as NeoVim
is started in the project.

**Hot code replace**: while the debugger is attached, saving a Java file makes jdtls compile it and replace
the class in the running JVM, like "Update classes" in IntelliJ. This works for changes inside method
bodies. New methods, fields or classes and changed signatures need `<leader>wr`. Changes to resources
like Facelets, JavaScript or properties need a rebuild unless the application reads them from the
sources (see the `jvm_args` example above).

Other servers or applications (Jetty, `spring-boot:run`, a remote server) can be debugged by starting
them with `-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005` and attaching with
`<leader>da`.

## Debugging

| Keys | Action |
|------|--------|
| `<F5>` | Start or continue. Offers the main classes of the project and "Attach to a remote JVM" |
| `<F1>` / `<F2>` / `<F3>` | Step into / over / out |
| `<leader>b` / `<leader>B` | Toggle breakpoint / conditional breakpoint |
| `<leader>dp` | Log point (prints a message instead of stopping) |
| `<leader>dc` | Run to cursor |
| `<leader>de` | Evaluate the expression under the cursor or the selection |
| `<leader>dr` | Toggle the REPL (evaluate any Java expression in the current frame) |
| `<leader>da` | Attach to a JVM on a port |
| `<leader>dl` | Run the last debug configuration again |
| `<leader>dx` | Terminate |
| `<F7>` | Toggle the debugger UI |

The debugger UI opens and closes automatically. Variable values are shown next to the code.

## Tests

| Keys | Action |
|------|--------|
| `<leader>Tn` | Run the nearest test |
| `<leader>Td` | Debug the nearest test |
| `<leader>Tf` | Run all tests of the file |
| `<leader>Tl` | Run the last test again |
| `<leader>Ts` | Test tree of the project with results |
| `<leader>To` | Output of the test under the cursor |
| `<leader>TO` | Output panel |
| `<leader>Tx` | Stop the test run |
| `]t` / `[t` | Next / previous failed test |

neotest-java compiles changed classes through jdtls and runs JUnit 5 tests with the classpath of the
project. `<leader>Jt` and `<leader>JT` start tests through jdtls directly, which is handy for debugging a
single test. `<leader>rT` runs a test class with Maven/Gradle, exactly like the CI does.

## Spring Boot

In projects that depend on Spring Boot, the Spring Boot language server adds completion and validation
for `application.properties`/`application.yml`, navigation to beans and request mappings, and Spring
specific code actions. In other projects it does not start.

## Jakarta Faces (Facelets)

- `.xhtml` files are highlighted as HTML. The XML language server (lemminx) checks that they are well-formed.
- `gd` on an EL expression like `#{userBean.name}` jumps to the bean. It finds the bean by its name in
  `@Named`, `@ManagedBean`, `@Component` or `@Service`, else by the class name (`UserBean`). On the
  property, it jumps to the getter, the method or the field. Getters declared in a superclass are not found.
- There is no tag completion for PrimeFaces/OmniFaces components and no EL validation. IntelliJ Ultimate is
  better here.

## JPA and databases

jdtls understands the JPA annotations as plain Java. There are no JPA specific inspections (e.g. checking
JPQL queries against the entities).

For the database itself use the database UI:

| Keys | Action |
|------|--------|
| `<leader>Du` | Toggle the database UI |
| `<leader>Da` | Add a connection, e.g. `postgresql://user:password@localhost:5432/db` |

In the UI, `<CR>` opens tables and saved queries, `<leader>S` in a query buffer runs the query. SQL
buffers complete tables and columns. Connections are stored in `~/.local/share/nvim/db_ui`. Supported are
PostgreSQL, MySQL/MariaDB, SQL Server, Oracle, SQLite and others, but not H2.

XML files like `persistence.xml`, `pom.xml` and Liquibase changelogs get completion and validation from
lemminx if they reference an XML schema.

## Git and reviews

| Keys | Action |
|------|--------|
| `<leader>gs` | Git status (fugitive): `s`/`u` stage/unstage, `=` inline diff, `cc` commit, `g?` help |
| `<leader>gd` | Diff of all local changes, file by file, side by side |
| `<leader>gr` | Review the current branch: all changes since it forked from the merge request target (or the default branch) |
| `<leader>gm` | Pick an open merge request (GitLab) or pull request (GitHub), check it out and review it |
| `<leader>gM` | Open the merge request of the current branch in the browser |
| `<leader>gh` | History of the current file. In visual mode: history of the selected lines |
| `<leader>gH` | History of the branch |
| `<leader>gq` | Close the diff view |
| `<leader>gb` | Blame |
| `]c` / `[c` | Next / previous change in the file |
| `<leader>hs` / `<leader>hr` / `<leader>hp` | Stage / reset / preview the hunk under the cursor |

In the diff view, `<Tab>`/`<S-Tab>` go to the next/previous file, `-` stages or unstages a file,
`<leader>e` focuses the file panel and `g?` shows all mappings. `:Review <branch>` compares with any branch.

Comments on merge requests are not available in NeoVim. `<leader>gM` opens the merge request in the
browser to write them.

## Same keys in IntelliJ

`ideavim/.ideavimrc` maps the same keys to the corresponding IntelliJ actions (navigation, search,
`<leader>J`, tests, debugging, run configurations, server, Git, database), so you can switch between both
editors without relearning. Keys without a counterpart (e.g. `<leader>Jr`, `<leader>tl`) do nothing in
IntelliJ.

## Troubleshooting

- **Errors that the Maven build does not show**: `<leader>Ju` updates the project configuration. If that
  does not help, `<leader>Jw` deletes the jdtls workspace and imports the project again.
- **Lombok methods are unknown**: check the notification when jdtls starts. If the project's Lombok is
  not downloaded yet, build the project once and restart jdtls (`<leader>Jr`).
- **Logs**: `:JdtShowLogs` for jdtls, `:LspLog` for all language servers, `:checkhealth vim.lsp` for the
  attached servers, `:checkhealth neotest-java` for the tests.
- **Old jdtls workspaces** of projects you no longer use can be deleted from
  `~/.cache/nvim/jdtls/workspaces/`.

## Where the configuration lives

| File | Content |
|------|---------|
| `ftplugin/java.lua` | Starts jdtls for Java buffers |
| `ftplugin/xhtml.lua` | `gd` for EL expressions |
| `lua/config/java/project.lua` | Project root, modules, build tool, JDKs, Lombok |
| `lua/config/java/jdtls.lua` | jdtls command, settings and Java mappings |
| `lua/config/java/spotless.lua` | Spotless formatter for conform.nvim |
| `lua/config/java/tasks.lua` | Maven/Gradle build tasks for overseer |
| `lua/config/java/run.lua` | Run configurations, Tomcat runner, `:JavaServer` |
| `lua/config/java/intellij.lua` | Reads IntelliJ run configurations |
| `lua/config/java/symbols.lua` | Workspace symbol search without a Java buffer |
| `lua/overseer/component/java/attach_debugger.lua` | Attaches the debugger when a server starts |
| `lua/config/run_status.lua` | Run indicator in the statusline |
| `lua/config/java/settings.lua` | Project settings |
| `lua/config/java/faces.lua` | EL navigation |
| `lua/config/git_review.lua` | Merge request reviews |
| `lua/plugins/java.lua` | nvim-jdtls, neotest, spring-boot.nvim |
| `lua/plugins/debug.lua` | nvim-dap |
| `lua/plugins/tasks.lua` | overseer, build and server mappings |
| `lua/plugins/database.lua` | Database UI |
| `lua/plugins/git.lua` | gitsigns, fugitive, diffview |
| `lua/plugins/language_support.lua` | Other language servers, formatters, treesitter |
