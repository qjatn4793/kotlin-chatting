package com.bspay.payment
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import kotlin.random.Random

data class PaymentReq(val orderId: Long, val amount: Long)
data class PaymentRes(val approved: Boolean, val reason: String? = null)

@RestController
@RequestMapping("/payments")
class PaymentController {
    @PostMapping("/authorize")
    fun authorize(@RequestBody req: PaymentReq): ResponseEntity<PaymentRes> {
        val ok = Random.nextDouble() < 0.8
        return if (ok) ResponseEntity.ok(PaymentRes(true))
        else ResponseEntity.ok(PaymentRes(false, "INSUFFICIENT_FUNDS"))
    }
}
