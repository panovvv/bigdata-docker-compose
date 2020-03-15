import sys

from pyspark.shell import spark

print(sys.version)
print("Arguments: \n" + str(sys.argv))

try:
    num = int(sys.argv[1])
    print("Custom number passed in args: " + str(num))
except (ValueError, IndexError):
    num = 1000
    print("Can't process as number: " + sys.argv[1])

# Checking if f-string are available (python>=3.6)
print(f"Will raise {num} to the power of 3...")

cube = spark.range(num * num * num).count()
print(f"{num} ^ 3 = {cube}")
