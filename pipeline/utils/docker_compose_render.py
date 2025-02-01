"""
Title: Docker-compose Jinja template renderer
Description: This script renders the variables from a multi-level YAML file into a Jinja formatted template file. The resulting file is named after the original template file but with the extension provided in the command-line arguments.

For the variables "nso.container_name" and "container_network", the git branch name and latest commit hash [0:4] will be appended

Author: @ponchotitlan

Usage:
    python render_template.py <template_file> <yaml_file> <output_extension>

Options:
    <template_file>         Path to the input template file.
    <yaml_file>             Path to the input variables file.
    <output_extension>      Extension of the rendered file. Must not contain the dot '.'
"""

__author__ = "@ponchotitlan"

import os
import sys
import yaml
import subprocess
from jinja2 import Environment, FileSystemLoader


def get_current_branch() -> str:
    """Get the current Git branch name."""
    try:
        branch_name = subprocess.check_output(
            ['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
            stderr=subprocess.DEVNULL
        ).strip().decode('utf-8')
        return branch_name
    except subprocess.CalledProcessError:
        return 'local'
    
    
def get_latest_commit_hash() -> str:
    """Get the latest commit hash."""
    try:
        commit_hash = subprocess.check_output(
            ['git', 'rev-parse', 'HEAD'],
            stderr=subprocess.DEVNULL
        ).strip().decode('utf-8')
        return commit_hash
    except subprocess.CalledProcessError:
        return '0000'
    
    
def get_git_suffix() -> str:
    """Returns a suffix in the following format: _{get_current_branch()}_{get_latest_commit_hash()[0:4]}"""
    return f"_{get_current_branch()}_{get_latest_commit_hash()[0:4]}"


def render_template(template_dir, template_file, yaml_file, output_extension): 
    # Load the YAML file
    with open(yaml_file, 'r') as f:
        yaml_data = yaml.safe_load(f)
        
    # Appending of the suffix to the records nso.container_name and container_network
    try:
        yaml_data['nso']['container_name'] = f"{yaml_data['nso']['container_name']}{get_git_suffix()}"
        yaml_data['container_network'] = f"{yaml_data['container_network']}{get_git_suffix()}"
    except:
        pass

    # Set up the Jinja2 environment
    env = Environment(loader=FileSystemLoader(template_dir))
    template = env.get_template(template_file)
    
    # Render the template with the YAML data
    rendered_content = template.render(yaml_data)
    
    # Define the output file path
    base_name, _ = os.path.splitext(template_file)
    output_file = f"{base_name}.{output_extension}"
    output_path = os.path.join(template_dir, output_file)
    
    # Write the rendered content to the output file
    with open(output_path, 'w') as f:
        f.write(rendered_content)

    print(f"Rendered file written to: {output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python render_template.py <template_file> <yaml_file> <output_extension>")
        sys.exit(1)

    template_file = sys.argv[1]
    yaml_file = sys.argv[2]
    output_extension = sys.argv[3]

    # Get the directory of the template file
    template_dir = os.path.dirname(template_file)

    render_template(template_dir, os.path.basename(template_file), yaml_file, output_extension)