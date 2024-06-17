# 定义编译器和编译选项
CXX = clang++
CXXFLAGS = -std=c++11 `llvm-config --cxxflags`
LDFLAGS = `llvm-config --ldflags --system-libs --libs all`

# 定义目标文件
TARGET = DebugInserter
SRC = DebugInserter.cpp

# 默认目标
all: $(TARGET)

# 编译目标
$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)

# 运行工具
run: $(TARGET)
	./$(TARGET) path/to/your/source.cpp

# 清理生成的文件
clean:
	rm -f $(TARGET)