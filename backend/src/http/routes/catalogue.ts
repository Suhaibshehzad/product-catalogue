import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import type { CatalogueService } from '../../services/catalogue-service.js';

const searchQuery = z.object({ q: z.string().trim().max(100).optional() });
const slugParams = z.object({ slug: z.string().regex(/^[a-z0-9-]{1,64}$/) });
const idParams = z.object({ id: z.string().regex(/^[A-Za-z0-9_-]{1,64}$/) });

export const catalogueRoutes =
  (catalogue: CatalogueService): FastifyPluginAsync =>
  async (app) => {
    app.get('/products/featured', async () => ({ products: await catalogue.featuredProducts() }));

    app.get('/categories', async () => ({ categories: await catalogue.listCategories() }));

    app.get('/categories/:slug', async (request) => {
      const { slug } = slugParams.parse(request.params);
      return catalogue.categoryPage(slug);
    });

    // No `q` (or a blank one) lists everything, which also serves "browse all".
    app.get('/products', async (request) => {
      const { q } = searchQuery.parse(request.query);
      return { products: await catalogue.search(q ?? '') };
    });

    app.get('/products/:id', async (request) => {
      const { id } = idParams.parse(request.params);
      return { product: await catalogue.product(id) };
    });
  };
