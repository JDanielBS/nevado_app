"""Compara modelos locales con las mismas preguntas, con y sin una ficha como contexto.

Uso (desde la raíz del proyecto):
    python3 eval/comparar_modelos.py

Requiere llama-server compilado en ~/herramientas/llama.cpp/build/bin/ y los modelos en ~/modelos/.
Solo usa la biblioteca estándar y se conecta únicamente a 127.0.0.1.
Las respuestas se guardan en eval/resultados/comparacion_modelos.json y .md para revisarlas a mano.
"""

import json
import subprocess
import time
import urllib.request
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
SERVIDOR = Path.home() / "herramientas/llama.cpp/build/bin/llama-server"
MODELOS = {
    "Qwen2.5 1.5B": Path.home() / "modelos/qwen2.5-1.5b/qwen2.5-1.5b-instruct-q4_k_m.gguf",
    "Gemma 3 1B": Path.home() / "modelos/gemma-3-1b/gemma-3-1b-it-Q4_K_M.gguf",
}
PUERTO = 8899
# Pocos hilos para que la diferencia entre modelos se parezca más a la de un celular.
HILOS = 4
SIN_DATO = "No tengo información verificada sobre eso."
SISTEMA_SOLO = (
    "Eres un asistente para visitantes de un parque natural de alta montaña. Responde en español, breve."
)
SISTEMA_FICHA = (
    "Eres un asistente para visitantes de un parque natural de alta montaña. Responde en español, breve, "
    "usando únicamente la información de la ficha. No agregues datos ni consejos que no estén en ella. "
    f'Si la ficha no responde la pregunta, contesta exactamente: "{SIN_DATO}"'
)


def pedir(ruta, cuerpo=None, espera=180):
    datos = json.dumps(cuerpo).encode() if cuerpo else None
    peticion = urllib.request.Request(
        f"http://127.0.0.1:{PUERTO}{ruta}", data=datos, headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(peticion, timeout=espera) as respuesta:
        return json.load(respuesta)


def esperar_servidor(proceso):
    for _ in range(180):
        if proceso.poll() is not None:
            raise RuntimeError("llama-server terminó antes de estar listo")
        try:
            if pedir("/health", espera=2).get("status") == "ok":
                return
        except OSError:
            pass
        time.sleep(1)
    raise RuntimeError("llama-server no respondió a tiempo")


def memoria_mb(pid):
    for linea in Path(f"/proc/{pid}/status").read_text().splitlines():
        if linea.startswith("VmRSS:"):
            return round(int(linea.split()[1]) / 1024)
    return None


def preguntar(sistema, usuario):
    r = pedir(
        "/v1/chat/completions",
        {
            "messages": [{"role": "system", "content": sistema}, {"role": "user", "content": usuario}],
            "temperature": 0.2,
            "seed": 42,
            "max_tokens": 120,
            "cache_prompt": False,
        },
    )
    tiempos = r.get("timings", {})
    return {
        "respuesta": r["choices"][0]["message"]["content"].strip(),
        "segundos": round((tiempos.get("prompt_ms", 0) + tiempos.get("predicted_ms", 0)) / 1000, 2),
        "tokens_por_segundo": round(tiempos.get("predicted_per_second", 0), 1),
    }


def evaluar(ruta_modelo, preguntas, fichas):
    proceso = subprocess.Popen(
        [str(SERVIDOR), "-m", str(ruta_modelo), "--host", "127.0.0.1", "--port", str(PUERTO),
         "-c", "2048", "-t", str(HILOS), "-ngl", "0", "-np", "1"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    try:
        esperar_servidor(proceso)
        resultados = []
        for p in preguntas:
            ficha = fichas[p["ficha"]]
            con_ficha = f"Ficha «{ficha['titulo']}»: {ficha['texto']}\n\nPregunta: {p['pregunta']}"
            resultados.append(
                {**p, "solo": preguntar(SISTEMA_SOLO, p["pregunta"]),
                 "con_ficha": preguntar(SISTEMA_FICHA, con_ficha)}
            )
            print(f"  {p['id']}", flush=True)
        return {"memoria_mb": memoria_mb(proceso.pid), "resultados": resultados}
    finally:
        proceso.terminate()
        proceso.wait(timeout=30)


def informe(salida, preguntas):
    lineas = ["# Respuestas de la comparación de modelos", ""]
    for modo, titulo in (("solo", "Sin ficha"), ("con_ficha", "Con ficha")):
        for i, p in enumerate(preguntas):
            lineas += [f"## {titulo}: {p['id']} ({p['tipo']}) {p['pregunta']}", ""]
            for nombre, datos in salida.items():
                r = datos["resultados"][i][modo]
                texto = " ".join(r["respuesta"].split())
                lineas.append(f"- **{nombre}** ({r['segundos']} s): {texto}")
            lineas.append("")
    return "\n".join(lineas)


def main():
    preguntas = json.loads((RAIZ / "eval/preguntas_modelos.json").read_text(encoding="utf-8"))
    ruta_fichas = RAIZ / "contenido/fichas.demo.json"
    fichas = {f["id"]: f for f in json.loads(ruta_fichas.read_text(encoding="utf-8"))}
    salida = {}
    for nombre, ruta in MODELOS.items():
        print(nombre, flush=True)
        salida[nombre] = evaluar(ruta, preguntas, fichas)
    destino = RAIZ / "eval/resultados"
    destino.mkdir(exist_ok=True)
    (destino / "comparacion_modelos.json").write_text(
        json.dumps(salida, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    (destino / "comparacion_modelos.md").write_text(informe(salida, preguntas), encoding="utf-8")
    for nombre, datos in salida.items():
        for modo in ("solo", "con_ficha"):
            r = [x[modo] for x in datos["resultados"]]
            print(f"{nombre} {modo}: {sum(x['segundos'] for x in r) / len(r):.2f} s de media, "
                  f"{sum(x['tokens_por_segundo'] for x in r) / len(r):.1f} tokens/s")
        print(f"{nombre}: {datos['memoria_mb']} MB de memoria")


if __name__ == "__main__":
    main()
