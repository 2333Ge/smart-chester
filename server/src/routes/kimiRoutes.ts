import { Router } from "express";
import { KimiController } from "../controllers/kimiController";

const router = Router();
const kimiController = new KimiController();

export function setKimiRoutes(app: Router) {
  app.use("/kimi", router);
  router.post("/call", kimiController.callKimiApi);
}
