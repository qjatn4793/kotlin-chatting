package com.bspay.orderqry
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/query")
class QueryController {
    @GetMapping("/health")
    fun health() = ResponseEntity.ok(mapOf("status" to "ok"))
}
