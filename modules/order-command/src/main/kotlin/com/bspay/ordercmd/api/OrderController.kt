package com.bspay.ordercmd.api

import com.bspay.ordercmd.domain.Order
import com.bspay.ordercmd.domain.OrderRepository
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import org.springframework.web.client.RestClient

data class CreateOrderReq(val userId: Long, val amount: Long)
data class PaymentReq(val orderId: Long, val amount: Long)
data class PaymentRes(val approved: Boolean, val reason: String? = null)

@RestController
@RequestMapping("/orders")
class OrderController(private val repo: OrderRepository) {

    // 간단히 동기 HTTP로 결제 호출 (후에 Kafka로 교체 가능)
    private val payment = RestClient.create("http://localhost:8082")

    @PostMapping
    fun create(@RequestBody req: CreateOrderReq): ResponseEntity<Order> {
        var order = repo.save(Order(userId = req.userId, amount = req.amount))
        val pay = payment.post().uri("/payments/authorize")
            .body(PaymentReq(order.id!!, req.amount))
            .retrieve().body(PaymentRes::class.java)

        if (pay?.approved == true) order.confirm() else order.cancel()
        order = repo.save(order)
        return ResponseEntity.ok(order)
    }

    @GetMapping("/{id}")
    fun get(@PathVariable id: Long) =
        repo.findById(id).map { ResponseEntity.ok(it) }.orElse(ResponseEntity.notFound().build())
}
