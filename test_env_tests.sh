# 1
docker build -t test-clang . --build-arg projects=FiberTaskingLib
docker run -v $testDir:/testDir -v $llvm:/llvm-project test-clang

# 2
docker build -t test-clang . --build-arg projects=enkiTS --build-arg delete=TRUE
docker run -v $testDir:/testDir -v $llvm:/llvm-project test-clang

# 3
docker build -t test-clang . --build-arg projects=FiberTaskingLib --build-arg delete=TRUE --build-arg setup=FALSE --build-arg checkers=cert-err58-cpp
docker run -v $testDir:/testDir -v $llvm:/llvm-project test-clang

# 4
docker build -t test-clang . --build-arg projects=tmux --build-arg analyze=FALSE
docker run -v $testDir:/testDir -v $llvm:/llvm-project test-clang


# 5 - 11
docker build -t test-clang . --build-arg projects=cpp-taskflow,postgres

# 5
docker run -v $testDir:/testDir -v $llvm:/llvm-project -e "projects=postgres" test-clang

# 6
docker run -v $testDir:/testDir -v $llvm:/llvm-project -e "projects=cpp-taskflow" -e "delete=TRUE" test-clang

# 7 
docker run -v $testDir:/testDir -v $llvm:/llvm-project -e "list=TRUE" test-clang

# 8
docker run -v $testDir:/testDir -v $llvm:/llvm-project -e "projects=postgres" -e "setup=FALSE" -e "checkers=cert-env33-c" test-clang

# 9
docker run -v $testDir:/testDir -v $llvm:/llvm-project -e "projects=postgres,cpp-taskflow" -e "checkers=cert-env33-c" -e "delete=TRUE" test-clang

# 10
docker run -v $testDir:/testDir -v $llvm:/llvm-project -e "projects=asd" test-clang

# 11
docker run -v $testDir:/testDir -v $llvm:/llvm-project -e "setup=FALSE" -e "checkers=bugprone-check-all" test-clang

# 12
docker run -v $llvm:/llvm-project -e "setup=FALSE" -e "checkers=bugprone-check-all" test-clang

# 13
docker run -v $testDir:/testDir test-clang

# 14
docker build -t test-clang . --build-arg projects=cpp-taskflow,random
