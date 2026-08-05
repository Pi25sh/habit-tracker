"""initial schema

Revision ID: 0001_initial
Revises:
Create Date: 2026-08-04
"""
from alembic import op
import sqlalchemy as sa

# The initial revision creates the full schema from the ORM metadata so it can
# never drift from the models. Subsequent revisions use `alembic revision
# --autogenerate` and contain explicit ops.
from app.models.models import Base

revision = "0001_initial"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    Base.metadata.create_all(bind=bind)

    # Seed built-in global categories (user_id NULL).
    bind.execute(sa.text("""
        INSERT INTO categories (id, user_id, name, icon, color, sort_order, created_at, updated_at)
        VALUES
          (gen_random_uuid(), NULL, 'Health',      'favorite',        '#E53935', 0, now(), now()),
          (gen_random_uuid(), NULL, 'Fitness',     'fitness_center',  '#43A047', 1, now(), now()),
          (gen_random_uuid(), NULL, 'Mindfulness', 'self_improvement','#8E24AA', 2, now(), now()),
          (gen_random_uuid(), NULL, 'Productivity','work',            '#1E88E5', 3, now(), now()),
          (gen_random_uuid(), NULL, 'Learning',    'school',          '#FB8C00', 4, now(), now()),
          (gen_random_uuid(), NULL, 'Finance',     'savings',         '#00897B', 5, now(), now())
    """))


def downgrade() -> None:
    Base.metadata.drop_all(bind=op.get_bind())
