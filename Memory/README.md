# PPA Team 2 SoC

첫 검증 대상은 테스트벤치에서 요청을 받는 동기식 RAM이다. CPU, NPU, GPU와의 통합은 후속 단계에서 다룬다.

```text
shared_mem_tb ── 읽기·쓰기 요청 ──▶ shared_mem
              ◀──── 읽기 응답 ─────
```

- [`rtl/shared_mem.sv`](rtl/shared_mem.sv)는 32비트 단일 포트 RAM이다. 기본 크기는 64워드(256바이트)다.
- [`tb/shared_mem_tb.sv`](tb/shared_mem_tb.sv)는 리셋, 전체 및 부분 쓰기, 첫 주소와 끝 주소, 연속 읽기를 검사한다.

`req_valid`와 `req_ready`가 모두 1인 클록 상승 에지에서 워드 주소와 요청을 받는다. 읽기 응답은 그 에지 직후 `rsp_valid`와 `rsp_rdata`에 등록된다. 수신측은 응답이 유효한 사이클에 이를 받을 수 있어야 한다. 쓰기는 읽기 응답을 생성하지 않으며 `req_wstrb[0]`은 하위 8비트를 선택한다. `rst`가 1이면 요청을 받지 않고, 다음 상승 에지에서 `rsp_valid`가 0이 된다. 메모리 내용은 리셋으로 초기화하지 않으므로 테스트에서 먼저 값을 쓴 후 읽는다.

## 시뮬레이션

저장소 루트에서 `build` 폴더를 만든 다음 Icarus Verilog로 실행한다. `+waves` 옵션은 `build/shared_mem.vcd` 파형을 생성한다.

```sh
mkdir build
iverilog -g2012 -s shared_mem_tb -o build/shared_mem.vvp rtl/shared_mem.sv tb/shared_mem_tb.sv
vvp build/shared_mem.vvp +waves
```

Vivado 2020.2 시뮬레이터에서도 같은 테스트를 실행할 수 있다. Vivado 명령이 잡힌 PowerShell에서 저장소 루트를 기준으로 실행한다.

```powershell
New-Item -ItemType Directory -Force build/xsim/build | Out-Null
Push-Location build/xsim
xvlog --sv ../../rtl/shared_mem.sv ../../tb/shared_mem_tb.sv
xelab --mt off shared_mem_tb -s shared_mem_tb_sim
xsim shared_mem_tb_sim --runall --testplusarg waves
Pop-Location
```

통과하면 `PASS: shared_mem ...`이 출력된다. Vivado에서 생성한 VCD 파형은 `build/xsim/build/shared_mem.vcd`에 있다.

TileLink 연결과 주소 변환, 여러 요청자에 대한 중재, PYNQ-Z2 합성은 별도 검증 단계다.
