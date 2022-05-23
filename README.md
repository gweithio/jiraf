<p align="center">
    <img src="misc/logo-slim.png" alt="Jiraf logo" style="width:65%">
    <br/>
    A Project creation tool for Odin
    <br/>
    <br/>
</p>


# Jiraf - Odin build tool that makes it easy to run, compile and test Odin projects.

Jiraf is a minimal build tool that makes it easy to run, compile and test Odin projects. It creates a basic project structure to get started. It is currently in active development and in its infancy. Feel free to read the [CONTRIBUTING](https://github.com/gweithio/jiraf/blob/main/CONTRIBUTING.md) if you wish to contribute to the project.

See [article on Jiraf](https://www.epmor.app/posts/introducing-jiraf) for some background information

## Building Jiraf
First clone the repo with submodules as dependencies are carried out this way until `jiraf get` becomes more functional.

```bash
$ git clone --recurse-submodules https://github.com/gweithio/jiraf
```

If you already have Jiraf installed. you can simply do `jiraf build` or use the makefile and type `make` in the parent directory

## Usage

## Minimum Commands

`-name` and `-type` are *required* commands can be done in any order

```bash
$ jiraf new -name:"ExampleProject" -type:exe 
```

See the `example/` for an example of what jiraf generates

## Full commands

```bash
$ jiraf new -name:"Test Project" -author:"ethan@epmor.app" -desc:"My cool project" -version:"0.1" -type:exe 
```

*As of v0.3* you can now run the following commands

Run your project
```bash
$ jiraf run -warnings-as-errors # Will run your project you can also pass in arguments to the compiler
$ jiraf build # Build your project
$ jiraf test # Will run your tests
$ jiraf get https://github.com/gweithio/arrays # The arrays package gets added the pkg directory
```

*NOTE*

For `jiraf get` the import for the example is pkg:arrays/src/arrays which is dependent on project structure of the dep you've just added

## Warnings

* Jiraf is still in development.
