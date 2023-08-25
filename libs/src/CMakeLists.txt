# core

set(TARGET ggwave)

add_library(${TARGET}
    ggwave.cpp
    )

target_include_directories(${TARGET} PUBLIC
    .
    ../include
    )

    find_library( # Defines the name of the path variable that stores the
    # location of the NDK library.
    log-lib

    # Specifies the name of the NDK library that
    # CMake needs to locate.
    log )
target_link_libraries( # Specifies the target library.
    # Links the log library to the target library.
    ggwave
    ${log-lib})

# if (BUILD_SHARED_LIBS)
#     target_link_libraries(${TARGET} PUBLIC
#         ${CMAKE_DL_LIBS}
#         )

#     target_compile_definitions(${TARGET} PUBLIC
#         GGWAVE_SHARED
#         )
# endif()

if (MINGW)
    target_link_libraries(${TARGET} PUBLIC
        stdc++
        )
endif()

install(DIRECTORY ../include/ggwave
    DESTINATION include
    )

install(TARGETS ${TARGET}
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib/static
    )
