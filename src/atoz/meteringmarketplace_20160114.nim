
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWSMarketplace Metering
## version: 2016-01-14
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Marketplace Metering Service</fullname> <p>This reference provides descriptions of the low-level AWS Marketplace Metering Service API.</p> <p>AWS Marketplace sellers can use this API to submit usage data for custom usage dimensions.</p> <p> <b>Submitting Metering Records</b> </p> <ul> <li> <p> <i>MeterUsage</i>- Submits the metering record for a Marketplace product. MeterUsage is called from an EC2 instance.</p> </li> <li> <p> <i>BatchMeterUsage</i>- Submits the metering record for a set of customers. BatchMeterUsage is called from a software-as-a-service (SaaS) application.</p> </li> </ul> <p> <b>Accepting New Customers</b> </p> <ul> <li> <p> <i>ResolveCustomer</i>- Called by a SaaS application during the registration process. When a buyer visits your website during the registration process, the buyer submits a Registration Token through the browser. The Registration Token is resolved through this API to obtain a CustomerIdentifier and Product Code.</p> </li> </ul> <p> <b>Entitlement and Metering for Paid Container Products</b> </p> <ul> <li> <p> Paid container software products sold through AWS Marketplace must integrate with the AWS Marketplace Metering Service and call the RegisterUsage operation for software entitlement and metering. Calling RegisterUsage from containers running outside of Amazon Elastic Container Service (Amazon ECR) isn't supported. Free and BYOL products for ECS aren't required to call RegisterUsage, but you can do so if you want to receive usage data in your seller reports. For more information on using the RegisterUsage operation, see <a href="https://docs.aws.amazon.com/marketplace/latest/userguide/container-based-products.html">Container-Based Products</a>. </p> </li> </ul> <p>BatchMeterUsage API calls are captured by AWS CloudTrail. You can use Cloudtrail to verify that the SaaS metering records that you sent are accurate by searching for records with the eventName of BatchMeterUsage. You can also use CloudTrail to audit records over time. For more information, see the <i> <a href="http://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-concepts.html">AWS CloudTrail User Guide</a> </i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/marketplace/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode): string

  OpenApiRestCall_772588 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772588](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772588): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get())

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "metering.marketplace.ap-northeast-1.amazonaws.com", "ap-southeast-1": "metering.marketplace.ap-southeast-1.amazonaws.com", "us-west-2": "metering.marketplace.us-west-2.amazonaws.com", "eu-west-2": "metering.marketplace.eu-west-2.amazonaws.com", "ap-northeast-3": "metering.marketplace.ap-northeast-3.amazonaws.com", "eu-central-1": "metering.marketplace.eu-central-1.amazonaws.com", "us-east-2": "metering.marketplace.us-east-2.amazonaws.com", "us-east-1": "metering.marketplace.us-east-1.amazonaws.com", "cn-northwest-1": "metering.marketplace.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "metering.marketplace.ap-south-1.amazonaws.com", "eu-north-1": "metering.marketplace.eu-north-1.amazonaws.com", "ap-northeast-2": "metering.marketplace.ap-northeast-2.amazonaws.com", "us-west-1": "metering.marketplace.us-west-1.amazonaws.com", "us-gov-east-1": "metering.marketplace.us-gov-east-1.amazonaws.com", "eu-west-3": "metering.marketplace.eu-west-3.amazonaws.com", "cn-north-1": "metering.marketplace.cn-north-1.amazonaws.com.cn", "sa-east-1": "metering.marketplace.sa-east-1.amazonaws.com", "eu-west-1": "metering.marketplace.eu-west-1.amazonaws.com", "us-gov-west-1": "metering.marketplace.us-gov-west-1.amazonaws.com", "ap-southeast-2": "metering.marketplace.ap-southeast-2.amazonaws.com", "ca-central-1": "metering.marketplace.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "metering.marketplace.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "metering.marketplace.ap-southeast-1.amazonaws.com",
      "us-west-2": "metering.marketplace.us-west-2.amazonaws.com",
      "eu-west-2": "metering.marketplace.eu-west-2.amazonaws.com",
      "ap-northeast-3": "metering.marketplace.ap-northeast-3.amazonaws.com",
      "eu-central-1": "metering.marketplace.eu-central-1.amazonaws.com",
      "us-east-2": "metering.marketplace.us-east-2.amazonaws.com",
      "us-east-1": "metering.marketplace.us-east-1.amazonaws.com",
      "cn-northwest-1": "metering.marketplace.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "metering.marketplace.ap-south-1.amazonaws.com",
      "eu-north-1": "metering.marketplace.eu-north-1.amazonaws.com",
      "ap-northeast-2": "metering.marketplace.ap-northeast-2.amazonaws.com",
      "us-west-1": "metering.marketplace.us-west-1.amazonaws.com",
      "us-gov-east-1": "metering.marketplace.us-gov-east-1.amazonaws.com",
      "eu-west-3": "metering.marketplace.eu-west-3.amazonaws.com",
      "cn-north-1": "metering.marketplace.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "metering.marketplace.sa-east-1.amazonaws.com",
      "eu-west-1": "metering.marketplace.eu-west-1.amazonaws.com",
      "us-gov-west-1": "metering.marketplace.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "metering.marketplace.ap-southeast-2.amazonaws.com",
      "ca-central-1": "metering.marketplace.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "meteringmarketplace"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_BatchMeterUsage_772924 = ref object of OpenApiRestCall_772588
proc url_BatchMeterUsage_772926(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchMeterUsage_772925(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>BatchMeterUsage is called from a SaaS application listed on the AWS Marketplace to post metering records for a set of customers.</p> <p>For identical requests, the API is idempotent; requests can be retried with the same records or a subset of the input records.</p> <p>Every request to BatchMeterUsage is for one product. If you need to meter usage for multiple products, you must make multiple calls to BatchMeterUsage.</p> <p>BatchMeterUsage can process up to 25 UsageRecords at a time.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773038 = header.getOrDefault("X-Amz-Date")
  valid_773038 = validateParameter(valid_773038, JString, required = false,
                                 default = nil)
  if valid_773038 != nil:
    section.add "X-Amz-Date", valid_773038
  var valid_773039 = header.getOrDefault("X-Amz-Security-Token")
  valid_773039 = validateParameter(valid_773039, JString, required = false,
                                 default = nil)
  if valid_773039 != nil:
    section.add "X-Amz-Security-Token", valid_773039
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773053 = header.getOrDefault("X-Amz-Target")
  valid_773053 = validateParameter(valid_773053, JString, required = true, default = newJString(
      "AWSMPMeteringService.BatchMeterUsage"))
  if valid_773053 != nil:
    section.add "X-Amz-Target", valid_773053
  var valid_773054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773054 = validateParameter(valid_773054, JString, required = false,
                                 default = nil)
  if valid_773054 != nil:
    section.add "X-Amz-Content-Sha256", valid_773054
  var valid_773055 = header.getOrDefault("X-Amz-Algorithm")
  valid_773055 = validateParameter(valid_773055, JString, required = false,
                                 default = nil)
  if valid_773055 != nil:
    section.add "X-Amz-Algorithm", valid_773055
  var valid_773056 = header.getOrDefault("X-Amz-Signature")
  valid_773056 = validateParameter(valid_773056, JString, required = false,
                                 default = nil)
  if valid_773056 != nil:
    section.add "X-Amz-Signature", valid_773056
  var valid_773057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773057 = validateParameter(valid_773057, JString, required = false,
                                 default = nil)
  if valid_773057 != nil:
    section.add "X-Amz-SignedHeaders", valid_773057
  var valid_773058 = header.getOrDefault("X-Amz-Credential")
  valid_773058 = validateParameter(valid_773058, JString, required = false,
                                 default = nil)
  if valid_773058 != nil:
    section.add "X-Amz-Credential", valid_773058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773082: Call_BatchMeterUsage_772924; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>BatchMeterUsage is called from a SaaS application listed on the AWS Marketplace to post metering records for a set of customers.</p> <p>For identical requests, the API is idempotent; requests can be retried with the same records or a subset of the input records.</p> <p>Every request to BatchMeterUsage is for one product. If you need to meter usage for multiple products, you must make multiple calls to BatchMeterUsage.</p> <p>BatchMeterUsage can process up to 25 UsageRecords at a time.</p>
  ## 
  let valid = call_773082.validator(path, query, header, formData, body)
  let scheme = call_773082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773082.url(scheme.get, call_773082.host, call_773082.base,
                         call_773082.route, valid.getOrDefault("path"))
  result = hook(call_773082, url, valid)

proc call*(call_773153: Call_BatchMeterUsage_772924; body: JsonNode): Recallable =
  ## batchMeterUsage
  ## <p>BatchMeterUsage is called from a SaaS application listed on the AWS Marketplace to post metering records for a set of customers.</p> <p>For identical requests, the API is idempotent; requests can be retried with the same records or a subset of the input records.</p> <p>Every request to BatchMeterUsage is for one product. If you need to meter usage for multiple products, you must make multiple calls to BatchMeterUsage.</p> <p>BatchMeterUsage can process up to 25 UsageRecords at a time.</p>
  ##   body: JObject (required)
  var body_773154 = newJObject()
  if body != nil:
    body_773154 = body
  result = call_773153.call(nil, nil, nil, nil, body_773154)

var batchMeterUsage* = Call_BatchMeterUsage_772924(name: "batchMeterUsage",
    meth: HttpMethod.HttpPost, host: "metering.marketplace.amazonaws.com",
    route: "/#X-Amz-Target=AWSMPMeteringService.BatchMeterUsage",
    validator: validate_BatchMeterUsage_772925, base: "/", url: url_BatchMeterUsage_772926,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MeterUsage_773193 = ref object of OpenApiRestCall_772588
proc url_MeterUsage_773195(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_MeterUsage_773194(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>API to emit metering records. For identical requests, the API is idempotent. It simply returns the metering record ID.</p> <p>MeterUsage is authenticated on the buyer's AWS account, generally when running from an EC2 instance on the AWS Marketplace.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773196 = header.getOrDefault("X-Amz-Date")
  valid_773196 = validateParameter(valid_773196, JString, required = false,
                                 default = nil)
  if valid_773196 != nil:
    section.add "X-Amz-Date", valid_773196
  var valid_773197 = header.getOrDefault("X-Amz-Security-Token")
  valid_773197 = validateParameter(valid_773197, JString, required = false,
                                 default = nil)
  if valid_773197 != nil:
    section.add "X-Amz-Security-Token", valid_773197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773198 = header.getOrDefault("X-Amz-Target")
  valid_773198 = validateParameter(valid_773198, JString, required = true, default = newJString(
      "AWSMPMeteringService.MeterUsage"))
  if valid_773198 != nil:
    section.add "X-Amz-Target", valid_773198
  var valid_773199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773199 = validateParameter(valid_773199, JString, required = false,
                                 default = nil)
  if valid_773199 != nil:
    section.add "X-Amz-Content-Sha256", valid_773199
  var valid_773200 = header.getOrDefault("X-Amz-Algorithm")
  valid_773200 = validateParameter(valid_773200, JString, required = false,
                                 default = nil)
  if valid_773200 != nil:
    section.add "X-Amz-Algorithm", valid_773200
  var valid_773201 = header.getOrDefault("X-Amz-Signature")
  valid_773201 = validateParameter(valid_773201, JString, required = false,
                                 default = nil)
  if valid_773201 != nil:
    section.add "X-Amz-Signature", valid_773201
  var valid_773202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773202 = validateParameter(valid_773202, JString, required = false,
                                 default = nil)
  if valid_773202 != nil:
    section.add "X-Amz-SignedHeaders", valid_773202
  var valid_773203 = header.getOrDefault("X-Amz-Credential")
  valid_773203 = validateParameter(valid_773203, JString, required = false,
                                 default = nil)
  if valid_773203 != nil:
    section.add "X-Amz-Credential", valid_773203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773205: Call_MeterUsage_773193; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>API to emit metering records. For identical requests, the API is idempotent. It simply returns the metering record ID.</p> <p>MeterUsage is authenticated on the buyer's AWS account, generally when running from an EC2 instance on the AWS Marketplace.</p>
  ## 
  let valid = call_773205.validator(path, query, header, formData, body)
  let scheme = call_773205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773205.url(scheme.get, call_773205.host, call_773205.base,
                         call_773205.route, valid.getOrDefault("path"))
  result = hook(call_773205, url, valid)

proc call*(call_773206: Call_MeterUsage_773193; body: JsonNode): Recallable =
  ## meterUsage
  ## <p>API to emit metering records. For identical requests, the API is idempotent. It simply returns the metering record ID.</p> <p>MeterUsage is authenticated on the buyer's AWS account, generally when running from an EC2 instance on the AWS Marketplace.</p>
  ##   body: JObject (required)
  var body_773207 = newJObject()
  if body != nil:
    body_773207 = body
  result = call_773206.call(nil, nil, nil, nil, body_773207)

var meterUsage* = Call_MeterUsage_773193(name: "meterUsage",
                                      meth: HttpMethod.HttpPost, host: "metering.marketplace.amazonaws.com", route: "/#X-Amz-Target=AWSMPMeteringService.MeterUsage",
                                      validator: validate_MeterUsage_773194,
                                      base: "/", url: url_MeterUsage_773195,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterUsage_773208 = ref object of OpenApiRestCall_772588
proc url_RegisterUsage_773210(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterUsage_773209(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Paid container software products sold through AWS Marketplace must integrate with the AWS Marketplace Metering Service and call the RegisterUsage operation for software entitlement and metering. Calling RegisterUsage from containers running outside of ECS is not currently supported. Free and BYOL products for ECS aren't required to call RegisterUsage, but you may choose to do so if you would like to receive usage data in your seller reports. The sections below explain the behavior of RegisterUsage. RegisterUsage performs two primary functions: metering and entitlement.</p> <ul> <li> <p> <i>Entitlement</i>: RegisterUsage allows you to verify that the customer running your paid software is subscribed to your product on AWS Marketplace, enabling you to guard against unauthorized use. Your container image that integrates with RegisterUsage is only required to guard against unauthorized use at container startup, as such a CustomerNotSubscribedException/PlatformNotSupportedException will only be thrown on the initial call to RegisterUsage. Subsequent calls from the same Amazon ECS task instance (e.g. task-id) will not throw a CustomerNotSubscribedException, even if the customer unsubscribes while the Amazon ECS task is still running.</p> </li> <li> <p> <i>Metering</i>: RegisterUsage meters software use per ECS task, per hour, with usage prorated to the second. A minimum of 1 minute of usage applies to tasks that are short lived. For example, if a customer has a 10 node ECS cluster and creates an ECS service configured as a Daemon Set, then ECS will launch a task on all 10 cluster nodes and the customer will be charged: (10 * hourly_rate). Metering for software use is automatically handled by the AWS Marketplace Metering Control Plane -- your software is not required to perform any metering specific actions, other than call RegisterUsage once for metering of software use to commence. The AWS Marketplace Metering Control Plane will also continue to bill customers for running ECS tasks, regardless of the customers subscription state, removing the need for your software to perform entitlement checks at runtime.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773211 = header.getOrDefault("X-Amz-Date")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Date", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Security-Token")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Security-Token", valid_773212
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773213 = header.getOrDefault("X-Amz-Target")
  valid_773213 = validateParameter(valid_773213, JString, required = true, default = newJString(
      "AWSMPMeteringService.RegisterUsage"))
  if valid_773213 != nil:
    section.add "X-Amz-Target", valid_773213
  var valid_773214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773214 = validateParameter(valid_773214, JString, required = false,
                                 default = nil)
  if valid_773214 != nil:
    section.add "X-Amz-Content-Sha256", valid_773214
  var valid_773215 = header.getOrDefault("X-Amz-Algorithm")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-Algorithm", valid_773215
  var valid_773216 = header.getOrDefault("X-Amz-Signature")
  valid_773216 = validateParameter(valid_773216, JString, required = false,
                                 default = nil)
  if valid_773216 != nil:
    section.add "X-Amz-Signature", valid_773216
  var valid_773217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773217 = validateParameter(valid_773217, JString, required = false,
                                 default = nil)
  if valid_773217 != nil:
    section.add "X-Amz-SignedHeaders", valid_773217
  var valid_773218 = header.getOrDefault("X-Amz-Credential")
  valid_773218 = validateParameter(valid_773218, JString, required = false,
                                 default = nil)
  if valid_773218 != nil:
    section.add "X-Amz-Credential", valid_773218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773220: Call_RegisterUsage_773208; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Paid container software products sold through AWS Marketplace must integrate with the AWS Marketplace Metering Service and call the RegisterUsage operation for software entitlement and metering. Calling RegisterUsage from containers running outside of ECS is not currently supported. Free and BYOL products for ECS aren't required to call RegisterUsage, but you may choose to do so if you would like to receive usage data in your seller reports. The sections below explain the behavior of RegisterUsage. RegisterUsage performs two primary functions: metering and entitlement.</p> <ul> <li> <p> <i>Entitlement</i>: RegisterUsage allows you to verify that the customer running your paid software is subscribed to your product on AWS Marketplace, enabling you to guard against unauthorized use. Your container image that integrates with RegisterUsage is only required to guard against unauthorized use at container startup, as such a CustomerNotSubscribedException/PlatformNotSupportedException will only be thrown on the initial call to RegisterUsage. Subsequent calls from the same Amazon ECS task instance (e.g. task-id) will not throw a CustomerNotSubscribedException, even if the customer unsubscribes while the Amazon ECS task is still running.</p> </li> <li> <p> <i>Metering</i>: RegisterUsage meters software use per ECS task, per hour, with usage prorated to the second. A minimum of 1 minute of usage applies to tasks that are short lived. For example, if a customer has a 10 node ECS cluster and creates an ECS service configured as a Daemon Set, then ECS will launch a task on all 10 cluster nodes and the customer will be charged: (10 * hourly_rate). Metering for software use is automatically handled by the AWS Marketplace Metering Control Plane -- your software is not required to perform any metering specific actions, other than call RegisterUsage once for metering of software use to commence. The AWS Marketplace Metering Control Plane will also continue to bill customers for running ECS tasks, regardless of the customers subscription state, removing the need for your software to perform entitlement checks at runtime.</p> </li> </ul>
  ## 
  let valid = call_773220.validator(path, query, header, formData, body)
  let scheme = call_773220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773220.url(scheme.get, call_773220.host, call_773220.base,
                         call_773220.route, valid.getOrDefault("path"))
  result = hook(call_773220, url, valid)

proc call*(call_773221: Call_RegisterUsage_773208; body: JsonNode): Recallable =
  ## registerUsage
  ## <p>Paid container software products sold through AWS Marketplace must integrate with the AWS Marketplace Metering Service and call the RegisterUsage operation for software entitlement and metering. Calling RegisterUsage from containers running outside of ECS is not currently supported. Free and BYOL products for ECS aren't required to call RegisterUsage, but you may choose to do so if you would like to receive usage data in your seller reports. The sections below explain the behavior of RegisterUsage. RegisterUsage performs two primary functions: metering and entitlement.</p> <ul> <li> <p> <i>Entitlement</i>: RegisterUsage allows you to verify that the customer running your paid software is subscribed to your product on AWS Marketplace, enabling you to guard against unauthorized use. Your container image that integrates with RegisterUsage is only required to guard against unauthorized use at container startup, as such a CustomerNotSubscribedException/PlatformNotSupportedException will only be thrown on the initial call to RegisterUsage. Subsequent calls from the same Amazon ECS task instance (e.g. task-id) will not throw a CustomerNotSubscribedException, even if the customer unsubscribes while the Amazon ECS task is still running.</p> </li> <li> <p> <i>Metering</i>: RegisterUsage meters software use per ECS task, per hour, with usage prorated to the second. A minimum of 1 minute of usage applies to tasks that are short lived. For example, if a customer has a 10 node ECS cluster and creates an ECS service configured as a Daemon Set, then ECS will launch a task on all 10 cluster nodes and the customer will be charged: (10 * hourly_rate). Metering for software use is automatically handled by the AWS Marketplace Metering Control Plane -- your software is not required to perform any metering specific actions, other than call RegisterUsage once for metering of software use to commence. The AWS Marketplace Metering Control Plane will also continue to bill customers for running ECS tasks, regardless of the customers subscription state, removing the need for your software to perform entitlement checks at runtime.</p> </li> </ul>
  ##   body: JObject (required)
  var body_773222 = newJObject()
  if body != nil:
    body_773222 = body
  result = call_773221.call(nil, nil, nil, nil, body_773222)

var registerUsage* = Call_RegisterUsage_773208(name: "registerUsage",
    meth: HttpMethod.HttpPost, host: "metering.marketplace.amazonaws.com",
    route: "/#X-Amz-Target=AWSMPMeteringService.RegisterUsage",
    validator: validate_RegisterUsage_773209, base: "/", url: url_RegisterUsage_773210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResolveCustomer_773223 = ref object of OpenApiRestCall_772588
proc url_ResolveCustomer_773225(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ResolveCustomer_773224(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## ResolveCustomer is called by a SaaS application during the registration process. When a buyer visits your website during the registration process, the buyer submits a registration token through their browser. The registration token is resolved through this API to obtain a CustomerIdentifier and product code.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773226 = header.getOrDefault("X-Amz-Date")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-Date", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Security-Token")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Security-Token", valid_773227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773228 = header.getOrDefault("X-Amz-Target")
  valid_773228 = validateParameter(valid_773228, JString, required = true, default = newJString(
      "AWSMPMeteringService.ResolveCustomer"))
  if valid_773228 != nil:
    section.add "X-Amz-Target", valid_773228
  var valid_773229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773229 = validateParameter(valid_773229, JString, required = false,
                                 default = nil)
  if valid_773229 != nil:
    section.add "X-Amz-Content-Sha256", valid_773229
  var valid_773230 = header.getOrDefault("X-Amz-Algorithm")
  valid_773230 = validateParameter(valid_773230, JString, required = false,
                                 default = nil)
  if valid_773230 != nil:
    section.add "X-Amz-Algorithm", valid_773230
  var valid_773231 = header.getOrDefault("X-Amz-Signature")
  valid_773231 = validateParameter(valid_773231, JString, required = false,
                                 default = nil)
  if valid_773231 != nil:
    section.add "X-Amz-Signature", valid_773231
  var valid_773232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773232 = validateParameter(valid_773232, JString, required = false,
                                 default = nil)
  if valid_773232 != nil:
    section.add "X-Amz-SignedHeaders", valid_773232
  var valid_773233 = header.getOrDefault("X-Amz-Credential")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-Credential", valid_773233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773235: Call_ResolveCustomer_773223; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## ResolveCustomer is called by a SaaS application during the registration process. When a buyer visits your website during the registration process, the buyer submits a registration token through their browser. The registration token is resolved through this API to obtain a CustomerIdentifier and product code.
  ## 
  let valid = call_773235.validator(path, query, header, formData, body)
  let scheme = call_773235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773235.url(scheme.get, call_773235.host, call_773235.base,
                         call_773235.route, valid.getOrDefault("path"))
  result = hook(call_773235, url, valid)

proc call*(call_773236: Call_ResolveCustomer_773223; body: JsonNode): Recallable =
  ## resolveCustomer
  ## ResolveCustomer is called by a SaaS application during the registration process. When a buyer visits your website during the registration process, the buyer submits a registration token through their browser. The registration token is resolved through this API to obtain a CustomerIdentifier and product code.
  ##   body: JObject (required)
  var body_773237 = newJObject()
  if body != nil:
    body_773237 = body
  result = call_773236.call(nil, nil, nil, nil, body_773237)

var resolveCustomer* = Call_ResolveCustomer_773223(name: "resolveCustomer",
    meth: HttpMethod.HttpPost, host: "metering.marketplace.amazonaws.com",
    route: "/#X-Amz-Target=AWSMPMeteringService.ResolveCustomer",
    validator: validate_ResolveCustomer_773224, base: "/", url: url_ResolveCustomer_773225,
    schemes: {Scheme.Https, Scheme.Http})
proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
