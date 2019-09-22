
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

  OpenApiRestCall_602420 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602420](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602420): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get)

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
  Call_BatchMeterUsage_602757 = ref object of OpenApiRestCall_602420
proc url_BatchMeterUsage_602759(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchMeterUsage_602758(path: JsonNode; query: JsonNode;
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
  var valid_602871 = header.getOrDefault("X-Amz-Date")
  valid_602871 = validateParameter(valid_602871, JString, required = false,
                                 default = nil)
  if valid_602871 != nil:
    section.add "X-Amz-Date", valid_602871
  var valid_602872 = header.getOrDefault("X-Amz-Security-Token")
  valid_602872 = validateParameter(valid_602872, JString, required = false,
                                 default = nil)
  if valid_602872 != nil:
    section.add "X-Amz-Security-Token", valid_602872
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602886 = header.getOrDefault("X-Amz-Target")
  valid_602886 = validateParameter(valid_602886, JString, required = true, default = newJString(
      "AWSMPMeteringService.BatchMeterUsage"))
  if valid_602886 != nil:
    section.add "X-Amz-Target", valid_602886
  var valid_602887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "X-Amz-Content-Sha256", valid_602887
  var valid_602888 = header.getOrDefault("X-Amz-Algorithm")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "X-Amz-Algorithm", valid_602888
  var valid_602889 = header.getOrDefault("X-Amz-Signature")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-Signature", valid_602889
  var valid_602890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-SignedHeaders", valid_602890
  var valid_602891 = header.getOrDefault("X-Amz-Credential")
  valid_602891 = validateParameter(valid_602891, JString, required = false,
                                 default = nil)
  if valid_602891 != nil:
    section.add "X-Amz-Credential", valid_602891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602915: Call_BatchMeterUsage_602757; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>BatchMeterUsage is called from a SaaS application listed on the AWS Marketplace to post metering records for a set of customers.</p> <p>For identical requests, the API is idempotent; requests can be retried with the same records or a subset of the input records.</p> <p>Every request to BatchMeterUsage is for one product. If you need to meter usage for multiple products, you must make multiple calls to BatchMeterUsage.</p> <p>BatchMeterUsage can process up to 25 UsageRecords at a time.</p>
  ## 
  let valid = call_602915.validator(path, query, header, formData, body)
  let scheme = call_602915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602915.url(scheme.get, call_602915.host, call_602915.base,
                         call_602915.route, valid.getOrDefault("path"))
  result = hook(call_602915, url, valid)

proc call*(call_602986: Call_BatchMeterUsage_602757; body: JsonNode): Recallable =
  ## batchMeterUsage
  ## <p>BatchMeterUsage is called from a SaaS application listed on the AWS Marketplace to post metering records for a set of customers.</p> <p>For identical requests, the API is idempotent; requests can be retried with the same records or a subset of the input records.</p> <p>Every request to BatchMeterUsage is for one product. If you need to meter usage for multiple products, you must make multiple calls to BatchMeterUsage.</p> <p>BatchMeterUsage can process up to 25 UsageRecords at a time.</p>
  ##   body: JObject (required)
  var body_602987 = newJObject()
  if body != nil:
    body_602987 = body
  result = call_602986.call(nil, nil, nil, nil, body_602987)

var batchMeterUsage* = Call_BatchMeterUsage_602757(name: "batchMeterUsage",
    meth: HttpMethod.HttpPost, host: "metering.marketplace.amazonaws.com",
    route: "/#X-Amz-Target=AWSMPMeteringService.BatchMeterUsage",
    validator: validate_BatchMeterUsage_602758, base: "/", url: url_BatchMeterUsage_602759,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MeterUsage_603026 = ref object of OpenApiRestCall_602420
proc url_MeterUsage_603028(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_MeterUsage_603027(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603029 = header.getOrDefault("X-Amz-Date")
  valid_603029 = validateParameter(valid_603029, JString, required = false,
                                 default = nil)
  if valid_603029 != nil:
    section.add "X-Amz-Date", valid_603029
  var valid_603030 = header.getOrDefault("X-Amz-Security-Token")
  valid_603030 = validateParameter(valid_603030, JString, required = false,
                                 default = nil)
  if valid_603030 != nil:
    section.add "X-Amz-Security-Token", valid_603030
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603031 = header.getOrDefault("X-Amz-Target")
  valid_603031 = validateParameter(valid_603031, JString, required = true, default = newJString(
      "AWSMPMeteringService.MeterUsage"))
  if valid_603031 != nil:
    section.add "X-Amz-Target", valid_603031
  var valid_603032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603032 = validateParameter(valid_603032, JString, required = false,
                                 default = nil)
  if valid_603032 != nil:
    section.add "X-Amz-Content-Sha256", valid_603032
  var valid_603033 = header.getOrDefault("X-Amz-Algorithm")
  valid_603033 = validateParameter(valid_603033, JString, required = false,
                                 default = nil)
  if valid_603033 != nil:
    section.add "X-Amz-Algorithm", valid_603033
  var valid_603034 = header.getOrDefault("X-Amz-Signature")
  valid_603034 = validateParameter(valid_603034, JString, required = false,
                                 default = nil)
  if valid_603034 != nil:
    section.add "X-Amz-Signature", valid_603034
  var valid_603035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603035 = validateParameter(valid_603035, JString, required = false,
                                 default = nil)
  if valid_603035 != nil:
    section.add "X-Amz-SignedHeaders", valid_603035
  var valid_603036 = header.getOrDefault("X-Amz-Credential")
  valid_603036 = validateParameter(valid_603036, JString, required = false,
                                 default = nil)
  if valid_603036 != nil:
    section.add "X-Amz-Credential", valid_603036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603038: Call_MeterUsage_603026; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>API to emit metering records. For identical requests, the API is idempotent. It simply returns the metering record ID.</p> <p>MeterUsage is authenticated on the buyer's AWS account, generally when running from an EC2 instance on the AWS Marketplace.</p>
  ## 
  let valid = call_603038.validator(path, query, header, formData, body)
  let scheme = call_603038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603038.url(scheme.get, call_603038.host, call_603038.base,
                         call_603038.route, valid.getOrDefault("path"))
  result = hook(call_603038, url, valid)

proc call*(call_603039: Call_MeterUsage_603026; body: JsonNode): Recallable =
  ## meterUsage
  ## <p>API to emit metering records. For identical requests, the API is idempotent. It simply returns the metering record ID.</p> <p>MeterUsage is authenticated on the buyer's AWS account, generally when running from an EC2 instance on the AWS Marketplace.</p>
  ##   body: JObject (required)
  var body_603040 = newJObject()
  if body != nil:
    body_603040 = body
  result = call_603039.call(nil, nil, nil, nil, body_603040)

var meterUsage* = Call_MeterUsage_603026(name: "meterUsage",
                                      meth: HttpMethod.HttpPost, host: "metering.marketplace.amazonaws.com", route: "/#X-Amz-Target=AWSMPMeteringService.MeterUsage",
                                      validator: validate_MeterUsage_603027,
                                      base: "/", url: url_MeterUsage_603028,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterUsage_603041 = ref object of OpenApiRestCall_602420
proc url_RegisterUsage_603043(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterUsage_603042(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603044 = header.getOrDefault("X-Amz-Date")
  valid_603044 = validateParameter(valid_603044, JString, required = false,
                                 default = nil)
  if valid_603044 != nil:
    section.add "X-Amz-Date", valid_603044
  var valid_603045 = header.getOrDefault("X-Amz-Security-Token")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-Security-Token", valid_603045
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603046 = header.getOrDefault("X-Amz-Target")
  valid_603046 = validateParameter(valid_603046, JString, required = true, default = newJString(
      "AWSMPMeteringService.RegisterUsage"))
  if valid_603046 != nil:
    section.add "X-Amz-Target", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Content-Sha256", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-Algorithm")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-Algorithm", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Signature")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Signature", valid_603049
  var valid_603050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-SignedHeaders", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-Credential")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-Credential", valid_603051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603053: Call_RegisterUsage_603041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Paid container software products sold through AWS Marketplace must integrate with the AWS Marketplace Metering Service and call the RegisterUsage operation for software entitlement and metering. Calling RegisterUsage from containers running outside of ECS is not currently supported. Free and BYOL products for ECS aren't required to call RegisterUsage, but you may choose to do so if you would like to receive usage data in your seller reports. The sections below explain the behavior of RegisterUsage. RegisterUsage performs two primary functions: metering and entitlement.</p> <ul> <li> <p> <i>Entitlement</i>: RegisterUsage allows you to verify that the customer running your paid software is subscribed to your product on AWS Marketplace, enabling you to guard against unauthorized use. Your container image that integrates with RegisterUsage is only required to guard against unauthorized use at container startup, as such a CustomerNotSubscribedException/PlatformNotSupportedException will only be thrown on the initial call to RegisterUsage. Subsequent calls from the same Amazon ECS task instance (e.g. task-id) will not throw a CustomerNotSubscribedException, even if the customer unsubscribes while the Amazon ECS task is still running.</p> </li> <li> <p> <i>Metering</i>: RegisterUsage meters software use per ECS task, per hour, with usage prorated to the second. A minimum of 1 minute of usage applies to tasks that are short lived. For example, if a customer has a 10 node ECS cluster and creates an ECS service configured as a Daemon Set, then ECS will launch a task on all 10 cluster nodes and the customer will be charged: (10 * hourly_rate). Metering for software use is automatically handled by the AWS Marketplace Metering Control Plane -- your software is not required to perform any metering specific actions, other than call RegisterUsage once for metering of software use to commence. The AWS Marketplace Metering Control Plane will also continue to bill customers for running ECS tasks, regardless of the customers subscription state, removing the need for your software to perform entitlement checks at runtime.</p> </li> </ul>
  ## 
  let valid = call_603053.validator(path, query, header, formData, body)
  let scheme = call_603053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603053.url(scheme.get, call_603053.host, call_603053.base,
                         call_603053.route, valid.getOrDefault("path"))
  result = hook(call_603053, url, valid)

proc call*(call_603054: Call_RegisterUsage_603041; body: JsonNode): Recallable =
  ## registerUsage
  ## <p>Paid container software products sold through AWS Marketplace must integrate with the AWS Marketplace Metering Service and call the RegisterUsage operation for software entitlement and metering. Calling RegisterUsage from containers running outside of ECS is not currently supported. Free and BYOL products for ECS aren't required to call RegisterUsage, but you may choose to do so if you would like to receive usage data in your seller reports. The sections below explain the behavior of RegisterUsage. RegisterUsage performs two primary functions: metering and entitlement.</p> <ul> <li> <p> <i>Entitlement</i>: RegisterUsage allows you to verify that the customer running your paid software is subscribed to your product on AWS Marketplace, enabling you to guard against unauthorized use. Your container image that integrates with RegisterUsage is only required to guard against unauthorized use at container startup, as such a CustomerNotSubscribedException/PlatformNotSupportedException will only be thrown on the initial call to RegisterUsage. Subsequent calls from the same Amazon ECS task instance (e.g. task-id) will not throw a CustomerNotSubscribedException, even if the customer unsubscribes while the Amazon ECS task is still running.</p> </li> <li> <p> <i>Metering</i>: RegisterUsage meters software use per ECS task, per hour, with usage prorated to the second. A minimum of 1 minute of usage applies to tasks that are short lived. For example, if a customer has a 10 node ECS cluster and creates an ECS service configured as a Daemon Set, then ECS will launch a task on all 10 cluster nodes and the customer will be charged: (10 * hourly_rate). Metering for software use is automatically handled by the AWS Marketplace Metering Control Plane -- your software is not required to perform any metering specific actions, other than call RegisterUsage once for metering of software use to commence. The AWS Marketplace Metering Control Plane will also continue to bill customers for running ECS tasks, regardless of the customers subscription state, removing the need for your software to perform entitlement checks at runtime.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603055 = newJObject()
  if body != nil:
    body_603055 = body
  result = call_603054.call(nil, nil, nil, nil, body_603055)

var registerUsage* = Call_RegisterUsage_603041(name: "registerUsage",
    meth: HttpMethod.HttpPost, host: "metering.marketplace.amazonaws.com",
    route: "/#X-Amz-Target=AWSMPMeteringService.RegisterUsage",
    validator: validate_RegisterUsage_603042, base: "/", url: url_RegisterUsage_603043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResolveCustomer_603056 = ref object of OpenApiRestCall_602420
proc url_ResolveCustomer_603058(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ResolveCustomer_603057(path: JsonNode; query: JsonNode;
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
  var valid_603059 = header.getOrDefault("X-Amz-Date")
  valid_603059 = validateParameter(valid_603059, JString, required = false,
                                 default = nil)
  if valid_603059 != nil:
    section.add "X-Amz-Date", valid_603059
  var valid_603060 = header.getOrDefault("X-Amz-Security-Token")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "X-Amz-Security-Token", valid_603060
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603061 = header.getOrDefault("X-Amz-Target")
  valid_603061 = validateParameter(valid_603061, JString, required = true, default = newJString(
      "AWSMPMeteringService.ResolveCustomer"))
  if valid_603061 != nil:
    section.add "X-Amz-Target", valid_603061
  var valid_603062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Content-Sha256", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-Algorithm")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-Algorithm", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Signature")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Signature", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-SignedHeaders", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-Credential")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Credential", valid_603066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603068: Call_ResolveCustomer_603056; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## ResolveCustomer is called by a SaaS application during the registration process. When a buyer visits your website during the registration process, the buyer submits a registration token through their browser. The registration token is resolved through this API to obtain a CustomerIdentifier and product code.
  ## 
  let valid = call_603068.validator(path, query, header, formData, body)
  let scheme = call_603068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603068.url(scheme.get, call_603068.host, call_603068.base,
                         call_603068.route, valid.getOrDefault("path"))
  result = hook(call_603068, url, valid)

proc call*(call_603069: Call_ResolveCustomer_603056; body: JsonNode): Recallable =
  ## resolveCustomer
  ## ResolveCustomer is called by a SaaS application during the registration process. When a buyer visits your website during the registration process, the buyer submits a registration token through their browser. The registration token is resolved through this API to obtain a CustomerIdentifier and product code.
  ##   body: JObject (required)
  var body_603070 = newJObject()
  if body != nil:
    body_603070 = body
  result = call_603069.call(nil, nil, nil, nil, body_603070)

var resolveCustomer* = Call_ResolveCustomer_603056(name: "resolveCustomer",
    meth: HttpMethod.HttpPost, host: "metering.marketplace.amazonaws.com",
    route: "/#X-Amz-Target=AWSMPMeteringService.ResolveCustomer",
    validator: validate_ResolveCustomer_603057, base: "/", url: url_ResolveCustomer_603058,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
