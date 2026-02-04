from __future__ import annotations

import argparse
import sys

from nuvion_app.config import DEFAULT_PORT, load_env, resolve_config_path, setup_config


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="nuv-agent")
    subparsers = parser.add_subparsers(dest="command", required=True)

    setup_parser = subparsers.add_parser("setup", help="Configure agent settings")
    setup_parser.add_argument("--config", help="Path to config env file")
    setup_parser.add_argument("--web", action="store_true", help="Force web setup")
    setup_parser.add_argument("--cli", action="store_true", help="Force CLI setup")
    setup_parser.add_argument("--host", default="127.0.0.1", help="Web UI bind address")
    setup_parser.add_argument("--port", type=int, default=DEFAULT_PORT, help="Web UI port")
    setup_parser.add_argument("--no-open", action="store_true", help="Do not open browser")
    setup_parser.add_argument("--advanced", action="store_true", help="Prompt all fields")

    run_parser = subparsers.add_parser("run", help="Run inference service")
    run_parser.add_argument("--config", help="Path to config env file")

    path_parser = subparsers.add_parser("config-path", help="Print resolved config path")
    path_parser.add_argument("--config", help="Path to config env file")

    return parser


def main() -> None:
    if sys.version_info < (3, 10):
        sys.stderr.write("Python 3.10+ is required.\\n")
        sys.exit(2)
    parser = _build_parser()
    args = parser.parse_args()

    if args.command == "setup":
        if args.web and args.cli:
            parser.error("--web and --cli are mutually exclusive")
        use_web = None
        if args.web:
            use_web = True
        if args.cli:
            use_web = False
        setup_config(
            config_path=args.config,
            use_web=use_web,
            host=args.host,
            port=args.port,
            open_browser=not args.no_open,
            advanced=args.advanced,
        )
        return

    if args.command == "run":
        load_env(args.config)
        from nuvion_app.inference.main import main as run_main

        run_main()
        return

    if args.command == "config-path":
        path = resolve_config_path(args.config)
        sys.stdout.write(str(path))
        sys.stdout.write("\n")
        return

    parser.print_help()


if __name__ == "__main__":
    main()
