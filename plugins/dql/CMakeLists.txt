PROJECT (dql)
SET(PROJECT_SRCS
    dql.cpp
)
SET(PROJECT_HDRS
    brain.h
    fc.h
    input.h
    layer.h
    loss_result.h
    regression.h
    relu.h
    trainer.h
    vol.h
    window.h
)
SET_SOURCE_FILES_PROPERTIES( ${PROJECT_HDRS} PROPERTIES HEADER_FILE_ONLY TRUE)
LIST(APPEND PROJECT_SRCS ${PROJECT_HDRS})
DFHACK_PLUGIN(dql ${PROJECT_SRCS} LINK_LIBRARIES ${PROJECT_LIBS})
