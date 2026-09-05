#!/usr/bin/env python
"""Initialize database tables and seed default data."""
import asyncio
import sys
import os

# Add backend to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.core.config import settings
from app.db.session import engine
from app.models.models import Base, Category
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select


async def init_db():
    """Create all tables and seed default categories."""
    # Create all tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        print("All tables created successfully!")

    # Seed default categories
    async with AsyncSession(engine) as db:
        # Check if categories already exist
        result = await db.execute(select(Category))
        existing = result.scalars().first()

        if not existing:
            default_categories = [
                Category(
                    name="Health & Fitness",
                    icon="🏃",
                    color="#EF4444",
                    sort_order=0
                ),
                Category(
                    name="Productivity",
                    icon="💼",
                    color="#3B82F6",
                    sort_order=1
                ),
                Category(
                    name="Learning",
                    icon="📚",
                    color="#8B5CF6",
                    sort_order=2
                ),
                Category(
                    name="Mindfulness",
                    icon="🧘",
                    color="#10B981",
                    sort_order=3
                ),
                Category(
                    name="Creative",
                    icon="🎨",
                    color="#F59E0B",
                    sort_order=4
                ),
                Category(
                    name="Social",
                    icon="👥",
                    color="#EC4899",
                    sort_order=5
                ),
                Category(
                    name="Finance",
                    icon="💰",
                    color="#6366F1",
                    sort_order=6
                ),
                Category(
                    name="Other",
                    icon="📦",
                    color="#6B7280",
                    sort_order=7
                ),
            ]

            db.add_all(default_categories)
            await db.commit()
            print(f"Seeded {len(default_categories)} default categories!")
        else:
            print("Categories already exist, skipping seed.")

    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(init_db())