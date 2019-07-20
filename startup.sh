#!/bin/sh

# Execute all startup logic of this application

echo "================================================================="
echo "Setting up the application..."
echo "================================================================="
echo
bin/setup

echo
echo "================================================================="
echo "Running app..."
echo "================================================================="
echo
bundle exec puma -p 3000 -C ./config/puma.rb
