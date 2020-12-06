# serverless-starter

`serveless-starter` provides all of the files that you need to begin a serverless project.

1. Download the latest release into your project:
   `curl -o serverless-starter.zip https://github.com/carlosonunez/serverless-starter/archive/v1.0.0.zip`
2. Unzip it into your project: `unzip serverless-starter.zip`
3. Create an environment dotfile and config.yml: `make create_env`.
4. Edit `.env` and `config.yml` in your favorite editor.
5. Hack on your code.
6. Run `make deploy_integration` to deploy an integration environment to test your stuff in.
   Delete it by running `make destroy_integration`.
7. When you're ready, deploy it into production: `make deploy_production`.

Run `make usage` to learn everything that you can do with the `Makefile` included with
`serverless-starter`.

## Examples

You can see a few example applications bootstrapped from `serverless-starter` in the
`examples` directory. These examples actually work. If you want to deploy them,
follow steps 1-4 from above and then run `scripts/run_example.sh [example-name]`

## Seeing function logs

If you'd like to see logs from your function, run: `scripts/logs.sh [function_name] [environment]`.
(This assumes the integration environment by default.)

## Encrypting and decrypting your environments

When you run `make create_env`, your environment's dotfile is added to your project's `.gitignore`
so that you never commit it by accident. Consequently, this also means that you'll lose
your environment settings if you change computers or continue your work in a different environment.

To prevent this from happening, encrypt your environment dotfile and commit _that_ so that you can
decrypt it into your new working environment.

To encrypt: `ENV_PASSWORD=your-password-here make encrypt_env`

To decrypt: `ENV_PASSWORD=your-password-here make decrypt_env`

Treat `ENV_PASSWORD` like the keys to your house (or the keys to your wallet)! Don't share it with
anyone, and don't commit it into `config.yml`!
