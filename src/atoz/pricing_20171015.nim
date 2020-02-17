
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Price List Service
## version: 2017-10-15
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>AWS Price List Service API (AWS Price List Service) is a centralized and convenient way to programmatically query Amazon Web Services for services, products, and pricing information. The AWS Price List Service uses standardized product attributes such as <code>Location</code>, <code>Storage Class</code>, and <code>Operating System</code>, and provides prices at the SKU level. You can use the AWS Price List Service to build cost control and scenario planning tools, reconcile billing data, forecast future spend for budgeting purposes, and provide cost benefit analysis that compare your internal workloads with AWS.</p> <p>Use <code>GetServices</code> without a service code to retrieve the service codes for all AWS services, then <code>GetServices</code> with a service code to retreive the attribute names for that service. After you have the service code and attribute names, you can use <code>GetAttributeValues</code> to see what values are available for an attribute. With the service code and an attribute name and value, you can use <code>GetProducts</code> to find specific products that you're interested in, such as an <code>AmazonEC2</code> instance, with a <code>Provisioned IOPS</code> <code>volumeType</code>.</p> <p>Service Endpoint</p> <p>AWS Price List Service API provides the following two endpoints:</p> <ul> <li> <p>https://api.pricing.us-east-1.amazonaws.com</p> </li> <li> <p>https://api.pricing.ap-south-1.amazonaws.com</p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/pricing/
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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_610649 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610649](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610649): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
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
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "api.pricing.ap-northeast-1.amazonaws.com", "ap-southeast-1": "api.pricing.ap-southeast-1.amazonaws.com",
                           "us-west-2": "api.pricing.us-west-2.amazonaws.com",
                           "eu-west-2": "api.pricing.eu-west-2.amazonaws.com", "ap-northeast-3": "api.pricing.ap-northeast-3.amazonaws.com", "eu-central-1": "api.pricing.eu-central-1.amazonaws.com",
                           "us-east-2": "api.pricing.us-east-2.amazonaws.com",
                           "us-east-1": "api.pricing.us-east-1.amazonaws.com", "cn-northwest-1": "api.pricing.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "api.pricing.ap-south-1.amazonaws.com", "eu-north-1": "api.pricing.eu-north-1.amazonaws.com", "ap-northeast-2": "api.pricing.ap-northeast-2.amazonaws.com",
                           "us-west-1": "api.pricing.us-west-1.amazonaws.com", "us-gov-east-1": "api.pricing.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "api.pricing.eu-west-3.amazonaws.com", "cn-north-1": "api.pricing.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "api.pricing.sa-east-1.amazonaws.com",
                           "eu-west-1": "api.pricing.eu-west-1.amazonaws.com", "us-gov-west-1": "api.pricing.us-gov-west-1.amazonaws.com", "ap-southeast-2": "api.pricing.ap-southeast-2.amazonaws.com", "ca-central-1": "api.pricing.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "api.pricing.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "api.pricing.ap-southeast-1.amazonaws.com",
      "us-west-2": "api.pricing.us-west-2.amazonaws.com",
      "eu-west-2": "api.pricing.eu-west-2.amazonaws.com",
      "ap-northeast-3": "api.pricing.ap-northeast-3.amazonaws.com",
      "eu-central-1": "api.pricing.eu-central-1.amazonaws.com",
      "us-east-2": "api.pricing.us-east-2.amazonaws.com",
      "us-east-1": "api.pricing.us-east-1.amazonaws.com",
      "cn-northwest-1": "api.pricing.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "api.pricing.ap-south-1.amazonaws.com",
      "eu-north-1": "api.pricing.eu-north-1.amazonaws.com",
      "ap-northeast-2": "api.pricing.ap-northeast-2.amazonaws.com",
      "us-west-1": "api.pricing.us-west-1.amazonaws.com",
      "us-gov-east-1": "api.pricing.us-gov-east-1.amazonaws.com",
      "eu-west-3": "api.pricing.eu-west-3.amazonaws.com",
      "cn-north-1": "api.pricing.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "api.pricing.sa-east-1.amazonaws.com",
      "eu-west-1": "api.pricing.eu-west-1.amazonaws.com",
      "us-gov-west-1": "api.pricing.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "api.pricing.ap-southeast-2.amazonaws.com",
      "ca-central-1": "api.pricing.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "pricing"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_DescribeServices_610987 = ref object of OpenApiRestCall_610649
proc url_DescribeServices_610989(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeServices_610988(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns the metadata for one service or a list of the metadata for all services. Use this without a service code to get the service codes for all services. Use it with a service code, such as <code>AmazonEC2</code>, to get information specific to that service, such as the attribute names available for that service. For example, some of the attribute names available for EC2 are <code>volumeType</code>, <code>maxIopsVolume</code>, <code>operation</code>, <code>locationType</code>, and <code>instanceCapacity10xlarge</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611101 = query.getOrDefault("MaxResults")
  valid_611101 = validateParameter(valid_611101, JString, required = false,
                                 default = nil)
  if valid_611101 != nil:
    section.add "MaxResults", valid_611101
  var valid_611102 = query.getOrDefault("NextToken")
  valid_611102 = validateParameter(valid_611102, JString, required = false,
                                 default = nil)
  if valid_611102 != nil:
    section.add "NextToken", valid_611102
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611116 = header.getOrDefault("X-Amz-Target")
  valid_611116 = validateParameter(valid_611116, JString, required = true, default = newJString(
      "AWSPriceListService.DescribeServices"))
  if valid_611116 != nil:
    section.add "X-Amz-Target", valid_611116
  var valid_611117 = header.getOrDefault("X-Amz-Signature")
  valid_611117 = validateParameter(valid_611117, JString, required = false,
                                 default = nil)
  if valid_611117 != nil:
    section.add "X-Amz-Signature", valid_611117
  var valid_611118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611118 = validateParameter(valid_611118, JString, required = false,
                                 default = nil)
  if valid_611118 != nil:
    section.add "X-Amz-Content-Sha256", valid_611118
  var valid_611119 = header.getOrDefault("X-Amz-Date")
  valid_611119 = validateParameter(valid_611119, JString, required = false,
                                 default = nil)
  if valid_611119 != nil:
    section.add "X-Amz-Date", valid_611119
  var valid_611120 = header.getOrDefault("X-Amz-Credential")
  valid_611120 = validateParameter(valid_611120, JString, required = false,
                                 default = nil)
  if valid_611120 != nil:
    section.add "X-Amz-Credential", valid_611120
  var valid_611121 = header.getOrDefault("X-Amz-Security-Token")
  valid_611121 = validateParameter(valid_611121, JString, required = false,
                                 default = nil)
  if valid_611121 != nil:
    section.add "X-Amz-Security-Token", valid_611121
  var valid_611122 = header.getOrDefault("X-Amz-Algorithm")
  valid_611122 = validateParameter(valid_611122, JString, required = false,
                                 default = nil)
  if valid_611122 != nil:
    section.add "X-Amz-Algorithm", valid_611122
  var valid_611123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611123 = validateParameter(valid_611123, JString, required = false,
                                 default = nil)
  if valid_611123 != nil:
    section.add "X-Amz-SignedHeaders", valid_611123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611147: Call_DescribeServices_610987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the metadata for one service or a list of the metadata for all services. Use this without a service code to get the service codes for all services. Use it with a service code, such as <code>AmazonEC2</code>, to get information specific to that service, such as the attribute names available for that service. For example, some of the attribute names available for EC2 are <code>volumeType</code>, <code>maxIopsVolume</code>, <code>operation</code>, <code>locationType</code>, and <code>instanceCapacity10xlarge</code>.
  ## 
  let valid = call_611147.validator(path, query, header, formData, body)
  let scheme = call_611147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611147.url(scheme.get, call_611147.host, call_611147.base,
                         call_611147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611147, url, valid)

proc call*(call_611218: Call_DescribeServices_610987; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeServices
  ## Returns the metadata for one service or a list of the metadata for all services. Use this without a service code to get the service codes for all services. Use it with a service code, such as <code>AmazonEC2</code>, to get information specific to that service, such as the attribute names available for that service. For example, some of the attribute names available for EC2 are <code>volumeType</code>, <code>maxIopsVolume</code>, <code>operation</code>, <code>locationType</code>, and <code>instanceCapacity10xlarge</code>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611219 = newJObject()
  var body_611221 = newJObject()
  add(query_611219, "MaxResults", newJString(MaxResults))
  add(query_611219, "NextToken", newJString(NextToken))
  if body != nil:
    body_611221 = body
  result = call_611218.call(nil, query_611219, nil, nil, body_611221)

var describeServices* = Call_DescribeServices_610987(name: "describeServices",
    meth: HttpMethod.HttpPost, host: "api.pricing.amazonaws.com",
    route: "/#X-Amz-Target=AWSPriceListService.DescribeServices",
    validator: validate_DescribeServices_610988, base: "/",
    url: url_DescribeServices_610989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttributeValues_611260 = ref object of OpenApiRestCall_610649
proc url_GetAttributeValues_611262(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAttributeValues_611261(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns a list of attribute values. Attibutes are similar to the details in a Price List API offer file. For a list of available attributes, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/reading-an-offer.html#pps-defs">Offer File Definitions</a> in the <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/billing-what-is.html">AWS Billing and Cost Management User Guide</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611263 = query.getOrDefault("MaxResults")
  valid_611263 = validateParameter(valid_611263, JString, required = false,
                                 default = nil)
  if valid_611263 != nil:
    section.add "MaxResults", valid_611263
  var valid_611264 = query.getOrDefault("NextToken")
  valid_611264 = validateParameter(valid_611264, JString, required = false,
                                 default = nil)
  if valid_611264 != nil:
    section.add "NextToken", valid_611264
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611265 = header.getOrDefault("X-Amz-Target")
  valid_611265 = validateParameter(valid_611265, JString, required = true, default = newJString(
      "AWSPriceListService.GetAttributeValues"))
  if valid_611265 != nil:
    section.add "X-Amz-Target", valid_611265
  var valid_611266 = header.getOrDefault("X-Amz-Signature")
  valid_611266 = validateParameter(valid_611266, JString, required = false,
                                 default = nil)
  if valid_611266 != nil:
    section.add "X-Amz-Signature", valid_611266
  var valid_611267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611267 = validateParameter(valid_611267, JString, required = false,
                                 default = nil)
  if valid_611267 != nil:
    section.add "X-Amz-Content-Sha256", valid_611267
  var valid_611268 = header.getOrDefault("X-Amz-Date")
  valid_611268 = validateParameter(valid_611268, JString, required = false,
                                 default = nil)
  if valid_611268 != nil:
    section.add "X-Amz-Date", valid_611268
  var valid_611269 = header.getOrDefault("X-Amz-Credential")
  valid_611269 = validateParameter(valid_611269, JString, required = false,
                                 default = nil)
  if valid_611269 != nil:
    section.add "X-Amz-Credential", valid_611269
  var valid_611270 = header.getOrDefault("X-Amz-Security-Token")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Security-Token", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Algorithm")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Algorithm", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-SignedHeaders", valid_611272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611274: Call_GetAttributeValues_611260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of attribute values. Attibutes are similar to the details in a Price List API offer file. For a list of available attributes, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/reading-an-offer.html#pps-defs">Offer File Definitions</a> in the <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/billing-what-is.html">AWS Billing and Cost Management User Guide</a>.
  ## 
  let valid = call_611274.validator(path, query, header, formData, body)
  let scheme = call_611274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611274.url(scheme.get, call_611274.host, call_611274.base,
                         call_611274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611274, url, valid)

proc call*(call_611275: Call_GetAttributeValues_611260; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getAttributeValues
  ## Returns a list of attribute values. Attibutes are similar to the details in a Price List API offer file. For a list of available attributes, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/reading-an-offer.html#pps-defs">Offer File Definitions</a> in the <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/billing-what-is.html">AWS Billing and Cost Management User Guide</a>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611276 = newJObject()
  var body_611277 = newJObject()
  add(query_611276, "MaxResults", newJString(MaxResults))
  add(query_611276, "NextToken", newJString(NextToken))
  if body != nil:
    body_611277 = body
  result = call_611275.call(nil, query_611276, nil, nil, body_611277)

var getAttributeValues* = Call_GetAttributeValues_611260(
    name: "getAttributeValues", meth: HttpMethod.HttpPost,
    host: "api.pricing.amazonaws.com",
    route: "/#X-Amz-Target=AWSPriceListService.GetAttributeValues",
    validator: validate_GetAttributeValues_611261, base: "/",
    url: url_GetAttributeValues_611262, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProducts_611278 = ref object of OpenApiRestCall_610649
proc url_GetProducts_611280(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetProducts_611279(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of all products that match the filter criteria.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_611281 = query.getOrDefault("MaxResults")
  valid_611281 = validateParameter(valid_611281, JString, required = false,
                                 default = nil)
  if valid_611281 != nil:
    section.add "MaxResults", valid_611281
  var valid_611282 = query.getOrDefault("NextToken")
  valid_611282 = validateParameter(valid_611282, JString, required = false,
                                 default = nil)
  if valid_611282 != nil:
    section.add "NextToken", valid_611282
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611283 = header.getOrDefault("X-Amz-Target")
  valid_611283 = validateParameter(valid_611283, JString, required = true, default = newJString(
      "AWSPriceListService.GetProducts"))
  if valid_611283 != nil:
    section.add "X-Amz-Target", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-Signature")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-Signature", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Content-Sha256", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Date")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Date", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Credential")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Credential", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Security-Token")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Security-Token", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Algorithm")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Algorithm", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-SignedHeaders", valid_611290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611292: Call_GetProducts_611278; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all products that match the filter criteria.
  ## 
  let valid = call_611292.validator(path, query, header, formData, body)
  let scheme = call_611292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611292.url(scheme.get, call_611292.host, call_611292.base,
                         call_611292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611292, url, valid)

proc call*(call_611293: Call_GetProducts_611278; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getProducts
  ## Returns a list of all products that match the filter criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611294 = newJObject()
  var body_611295 = newJObject()
  add(query_611294, "MaxResults", newJString(MaxResults))
  add(query_611294, "NextToken", newJString(NextToken))
  if body != nil:
    body_611295 = body
  result = call_611293.call(nil, query_611294, nil, nil, body_611295)

var getProducts* = Call_GetProducts_611278(name: "getProducts",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.pricing.amazonaws.com", route: "/#X-Amz-Target=AWSPriceListService.GetProducts",
                                        validator: validate_GetProducts_611279,
                                        base: "/", url: url_GetProducts_611280,
                                        schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
