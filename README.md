# sky2-bench

Benchmark runner for ruby-sky2 server.

## Benchmark runner

Every minute, ruby-sky2 executs:

```bash
$ bin/sky2-bench.sh
```

## Note

Result format:

```yml
metrics_unit: i/s
results:
  aref:
    2.6.3: 27.542
    2.6.3 --jit: 76.747
```

## License

MIT License
