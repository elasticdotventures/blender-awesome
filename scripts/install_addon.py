#!/usr/bin/env python3
"""
Blender Addon Installer Script
Installs and enables Blender addons via CLI

Usage:
    blender --background --python install_addon.py -- --addon addon_name
    python install_addon.py --addon addon_name --enable
"""
import bpy
import sys
import os
import shutil
import argparse
from pathlib import Path


def get_addon_dir():
    """Get the Blender addons directory"""
    blender_version = f"{bpy.app.version[0]}.{bpy.app.version[1]}"

    # Cross-platform addon directory
    if sys.platform == "win32":
        base = Path(os.environ.get("APPDATA", "~")) / "Blender Foundation" / "Blender" / blender_version / "scripts" / "addons"
    elif sys.platform == "darwin":
        base = Path.home() / "Library" / "Application Support" / "Blender" / blender_version / "scripts" / "addons"
    else:  # Linux
        base = Path.home() / ".config" / "blender" / blender_version / "scripts" / "addons"

    return base


def install_addon_from_file(filepath, addon_name=None):
    """Install an addon from a .py or .zip file"""
    filepath = Path(filepath)

    if not filepath.exists():
        print(f"❌ Error: File not found: {filepath}")
        return False

    addon_dir = get_addon_dir()
    addon_dir.mkdir(parents=True, exist_ok=True)

    try:
        if filepath.suffix == '.py':
            # Single Python file addon
            dest_name = addon_name if addon_name else filepath.name
            dest = addon_dir / dest_name
            shutil.copy2(filepath, dest)
            print(f"✅ Installed {dest_name} to {addon_dir}")
            return dest.stem  # Return module name without .py

        elif filepath.suffix == '.zip':
            # ZIP archive addon
            bpy.ops.preferences.addon_install(filepath=str(filepath))
            print(f"✅ Installed {filepath.name}")
            # Extract module name from ZIP (assuming standard structure)
            return addon_name if addon_name else filepath.stem

        else:
            print(f"❌ Error: Unsupported file type: {filepath.suffix}")
            return False

    except Exception as e:
        print(f"❌ Error installing addon: {e}")
        return False


def enable_addon(module_name):
    """Enable an addon by module name"""
    try:
        bpy.ops.preferences.addon_enable(module=module_name)
        bpy.ops.wm.save_userpref()
        print(f"✅ Enabled addon: {module_name}")
        return True
    except Exception as e:
        print(f"❌ Error enabling addon {module_name}: {e}")
        return False


def disable_addon(module_name):
    """Disable an addon by module name"""
    try:
        bpy.ops.preferences.addon_disable(module=module_name)
        bpy.ops.wm.save_userpref()
        print(f"✅ Disabled addon: {module_name}")
        return True
    except Exception as e:
        print(f"❌ Error disabling addon {module_name}: {e}")
        return False


def list_addons(enabled_only=False):
    """List all installed addons"""
    import addon_utils

    print(f"\n{'=' * 60}")
    print(f"{'Installed Blender Addons' if not enabled_only else 'Enabled Blender Addons'}")
    print(f"{'=' * 60}\n")

    addons = addon_utils.modules(refresh=False)

    for addon in addons:
        if enabled_only:
            if addon_utils.check(addon[0])[0]:
                print(f"  ✅ {addon[0]}")
        else:
            status = "✅" if addon_utils.check(addon[0])[0] else "⚪"
            print(f"  {status} {addon[0]}")

    print()


def verify_addon(module_name):
    """Verify an addon is installed and can be loaded"""
    import addon_utils

    try:
        # Try to enable it
        result = addon_utils.check(module_name)
        if result[0]:
            print(f"✅ Addon '{module_name}' is enabled and working")
            return True
        else:
            print(f"⚠️  Addon '{module_name}' is installed but not enabled")
            print(f"   Error: {result[1]}")
            return False
    except Exception as e:
        print(f"❌ Error verifying addon '{module_name}': {e}")
        return False


def main():
    """Main entry point"""
    # Parse arguments (handle both Blender and direct Python invocation)
    if '--' in sys.argv:
        # Running from Blender
        argv = sys.argv[sys.argv.index('--') + 1:]
    else:
        # Running directly
        argv = sys.argv[1:]

    parser = argparse.ArgumentParser(description='Install and manage Blender addons')
    parser.add_argument('--addon', help='Addon file (.py or .zip) or module name')
    parser.add_argument('--enable', action='store_true', help='Enable the addon after installation')
    parser.add_argument('--disable', action='store_true', help='Disable the addon')
    parser.add_argument('--list', action='store_true', help='List all installed addons')
    parser.add_argument('--list-enabled', action='store_true', help='List enabled addons only')
    parser.add_argument('--verify', action='store_true', help='Verify addon is working')
    parser.add_argument('--module-name', help='Module name for the addon (if different from filename)')

    args = parser.parse_args(argv)

    # List addons
    if args.list:
        list_addons(enabled_only=False)
        return

    if args.list_enabled:
        list_addons(enabled_only=True)
        return

    # Verify addon
    if args.verify and args.addon:
        verify_addon(args.addon)
        return

    # Disable addon
    if args.disable and args.addon:
        disable_addon(args.addon)
        return

    # Install and/or enable addon
    if args.addon:
        addon_path = Path(args.addon)

        # If it's a file, install it
        if addon_path.exists():
            module_name = install_addon_from_file(addon_path, args.module_name)
            if not module_name:
                sys.exit(1)
        else:
            # Assume it's a module name
            module_name = args.addon

        # Enable if requested
        if args.enable:
            enable_addon(module_name)
            verify_addon(module_name)
    else:
        parser.print_help()
        print("\n💡 Examples:")
        print("  # Install and enable addon:")
        print("  blender --background --python install_addon.py -- --addon addon.py --enable")
        print("\n  # List all addons:")
        print("  blender --background --python install_addon.py -- --list")
        print("\n  # Enable existing addon:")
        print("  blender --background --python install_addon.py -- --addon my_addon --enable")


if __name__ == "__main__":
    # Check if running in Blender
    try:
        import bpy
        main()
    except ImportError:
        print("❌ Error: This script must be run with Blender's Python:")
        print("   blender --background --python install_addon.py -- [options]")
        sys.exit(1)
