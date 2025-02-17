import { Router } from "express";
import { KimiController } from "../controllers/kimiController";

const router = Router();
const kimiController = new KimiController();

export function setKimiRoutes(app: Router) {
  app.use("/api", router);
  router.post("/chat", kimiController.callKimiApi);
}
