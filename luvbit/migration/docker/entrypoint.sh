#!/bin/bash

# Manage DBのマイグレーション
cd /migration
alembic upgrade head
