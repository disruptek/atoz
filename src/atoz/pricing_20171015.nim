
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_DescribeServices_602757 = ref object of OpenApiRestCall_602420
proc url_DescribeServices_602759(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeServices_602758(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns the metadata for one service or a list of the metadata for all services. Use this without a service code to get the service codes for all services. Use it with a service code, such as <code>AmazonEC2</code>, to get information specific to that service, such as the attribute names available for that service. For example, some of the attribute names available for EC2 are <code>volumeType</code>, <code>maxIopsVolume</code>, <code>operation</code>, <code>locationType</code>, and <code>instanceCapacity10xlarge</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_602871 = query.getOrDefault("NextToken")
  valid_602871 = validateParameter(valid_602871, JString, required = false,
                                 default = nil)
  if valid_602871 != nil:
    section.add "NextToken", valid_602871
  var valid_602872 = query.getOrDefault("MaxResults")
  valid_602872 = validateParameter(valid_602872, JString, required = false,
                                 default = nil)
  if valid_602872 != nil:
    section.add "MaxResults", valid_602872
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
  var valid_602873 = header.getOrDefault("X-Amz-Date")
  valid_602873 = validateParameter(valid_602873, JString, required = false,
                                 default = nil)
  if valid_602873 != nil:
    section.add "X-Amz-Date", valid_602873
  var valid_602874 = header.getOrDefault("X-Amz-Security-Token")
  valid_602874 = validateParameter(valid_602874, JString, required = false,
                                 default = nil)
  if valid_602874 != nil:
    section.add "X-Amz-Security-Token", valid_602874
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602888 = header.getOrDefault("X-Amz-Target")
  valid_602888 = validateParameter(valid_602888, JString, required = true, default = newJString(
      "AWSPriceListService.DescribeServices"))
  if valid_602888 != nil:
    section.add "X-Amz-Target", valid_602888
  var valid_602889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-Content-Sha256", valid_602889
  var valid_602890 = header.getOrDefault("X-Amz-Algorithm")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-Algorithm", valid_602890
  var valid_602891 = header.getOrDefault("X-Amz-Signature")
  valid_602891 = validateParameter(valid_602891, JString, required = false,
                                 default = nil)
  if valid_602891 != nil:
    section.add "X-Amz-Signature", valid_602891
  var valid_602892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602892 = validateParameter(valid_602892, JString, required = false,
                                 default = nil)
  if valid_602892 != nil:
    section.add "X-Amz-SignedHeaders", valid_602892
  var valid_602893 = header.getOrDefault("X-Amz-Credential")
  valid_602893 = validateParameter(valid_602893, JString, required = false,
                                 default = nil)
  if valid_602893 != nil:
    section.add "X-Amz-Credential", valid_602893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602917: Call_DescribeServices_602757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the metadata for one service or a list of the metadata for all services. Use this without a service code to get the service codes for all services. Use it with a service code, such as <code>AmazonEC2</code>, to get information specific to that service, such as the attribute names available for that service. For example, some of the attribute names available for EC2 are <code>volumeType</code>, <code>maxIopsVolume</code>, <code>operation</code>, <code>locationType</code>, and <code>instanceCapacity10xlarge</code>.
  ## 
  let valid = call_602917.validator(path, query, header, formData, body)
  let scheme = call_602917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602917.url(scheme.get, call_602917.host, call_602917.base,
                         call_602917.route, valid.getOrDefault("path"))
  result = hook(call_602917, url, valid)

proc call*(call_602988: Call_DescribeServices_602757; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeServices
  ## Returns the metadata for one service or a list of the metadata for all services. Use this without a service code to get the service codes for all services. Use it with a service code, such as <code>AmazonEC2</code>, to get information specific to that service, such as the attribute names available for that service. For example, some of the attribute names available for EC2 are <code>volumeType</code>, <code>maxIopsVolume</code>, <code>operation</code>, <code>locationType</code>, and <code>instanceCapacity10xlarge</code>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_602989 = newJObject()
  var body_602991 = newJObject()
  add(query_602989, "NextToken", newJString(NextToken))
  if body != nil:
    body_602991 = body
  add(query_602989, "MaxResults", newJString(MaxResults))
  result = call_602988.call(nil, query_602989, nil, nil, body_602991)

var describeServices* = Call_DescribeServices_602757(name: "describeServices",
    meth: HttpMethod.HttpPost, host: "api.pricing.amazonaws.com",
    route: "/#X-Amz-Target=AWSPriceListService.DescribeServices",
    validator: validate_DescribeServices_602758, base: "/",
    url: url_DescribeServices_602759, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttributeValues_603030 = ref object of OpenApiRestCall_602420
proc url_GetAttributeValues_603032(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAttributeValues_603031(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns a list of attribute values. Attibutes are similar to the details in a Price List API offer file. For a list of available attributes, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/reading-an-offer.html#pps-defs">Offer File Definitions</a> in the <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/billing-what-is.html">AWS Billing and Cost Management User Guide</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603033 = query.getOrDefault("NextToken")
  valid_603033 = validateParameter(valid_603033, JString, required = false,
                                 default = nil)
  if valid_603033 != nil:
    section.add "NextToken", valid_603033
  var valid_603034 = query.getOrDefault("MaxResults")
  valid_603034 = validateParameter(valid_603034, JString, required = false,
                                 default = nil)
  if valid_603034 != nil:
    section.add "MaxResults", valid_603034
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
  var valid_603035 = header.getOrDefault("X-Amz-Date")
  valid_603035 = validateParameter(valid_603035, JString, required = false,
                                 default = nil)
  if valid_603035 != nil:
    section.add "X-Amz-Date", valid_603035
  var valid_603036 = header.getOrDefault("X-Amz-Security-Token")
  valid_603036 = validateParameter(valid_603036, JString, required = false,
                                 default = nil)
  if valid_603036 != nil:
    section.add "X-Amz-Security-Token", valid_603036
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603037 = header.getOrDefault("X-Amz-Target")
  valid_603037 = validateParameter(valid_603037, JString, required = true, default = newJString(
      "AWSPriceListService.GetAttributeValues"))
  if valid_603037 != nil:
    section.add "X-Amz-Target", valid_603037
  var valid_603038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603038 = validateParameter(valid_603038, JString, required = false,
                                 default = nil)
  if valid_603038 != nil:
    section.add "X-Amz-Content-Sha256", valid_603038
  var valid_603039 = header.getOrDefault("X-Amz-Algorithm")
  valid_603039 = validateParameter(valid_603039, JString, required = false,
                                 default = nil)
  if valid_603039 != nil:
    section.add "X-Amz-Algorithm", valid_603039
  var valid_603040 = header.getOrDefault("X-Amz-Signature")
  valid_603040 = validateParameter(valid_603040, JString, required = false,
                                 default = nil)
  if valid_603040 != nil:
    section.add "X-Amz-Signature", valid_603040
  var valid_603041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603041 = validateParameter(valid_603041, JString, required = false,
                                 default = nil)
  if valid_603041 != nil:
    section.add "X-Amz-SignedHeaders", valid_603041
  var valid_603042 = header.getOrDefault("X-Amz-Credential")
  valid_603042 = validateParameter(valid_603042, JString, required = false,
                                 default = nil)
  if valid_603042 != nil:
    section.add "X-Amz-Credential", valid_603042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603044: Call_GetAttributeValues_603030; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of attribute values. Attibutes are similar to the details in a Price List API offer file. For a list of available attributes, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/reading-an-offer.html#pps-defs">Offer File Definitions</a> in the <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/billing-what-is.html">AWS Billing and Cost Management User Guide</a>.
  ## 
  let valid = call_603044.validator(path, query, header, formData, body)
  let scheme = call_603044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603044.url(scheme.get, call_603044.host, call_603044.base,
                         call_603044.route, valid.getOrDefault("path"))
  result = hook(call_603044, url, valid)

proc call*(call_603045: Call_GetAttributeValues_603030; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getAttributeValues
  ## Returns a list of attribute values. Attibutes are similar to the details in a Price List API offer file. For a list of available attributes, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/reading-an-offer.html#pps-defs">Offer File Definitions</a> in the <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/billing-what-is.html">AWS Billing and Cost Management User Guide</a>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603046 = newJObject()
  var body_603047 = newJObject()
  add(query_603046, "NextToken", newJString(NextToken))
  if body != nil:
    body_603047 = body
  add(query_603046, "MaxResults", newJString(MaxResults))
  result = call_603045.call(nil, query_603046, nil, nil, body_603047)

var getAttributeValues* = Call_GetAttributeValues_603030(
    name: "getAttributeValues", meth: HttpMethod.HttpPost,
    host: "api.pricing.amazonaws.com",
    route: "/#X-Amz-Target=AWSPriceListService.GetAttributeValues",
    validator: validate_GetAttributeValues_603031, base: "/",
    url: url_GetAttributeValues_603032, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProducts_603048 = ref object of OpenApiRestCall_602420
proc url_GetProducts_603050(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetProducts_603049(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of all products that match the filter criteria.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603051 = query.getOrDefault("NextToken")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "NextToken", valid_603051
  var valid_603052 = query.getOrDefault("MaxResults")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "MaxResults", valid_603052
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
  var valid_603053 = header.getOrDefault("X-Amz-Date")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "X-Amz-Date", valid_603053
  var valid_603054 = header.getOrDefault("X-Amz-Security-Token")
  valid_603054 = validateParameter(valid_603054, JString, required = false,
                                 default = nil)
  if valid_603054 != nil:
    section.add "X-Amz-Security-Token", valid_603054
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603055 = header.getOrDefault("X-Amz-Target")
  valid_603055 = validateParameter(valid_603055, JString, required = true, default = newJString(
      "AWSPriceListService.GetProducts"))
  if valid_603055 != nil:
    section.add "X-Amz-Target", valid_603055
  var valid_603056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603056 = validateParameter(valid_603056, JString, required = false,
                                 default = nil)
  if valid_603056 != nil:
    section.add "X-Amz-Content-Sha256", valid_603056
  var valid_603057 = header.getOrDefault("X-Amz-Algorithm")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "X-Amz-Algorithm", valid_603057
  var valid_603058 = header.getOrDefault("X-Amz-Signature")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "X-Amz-Signature", valid_603058
  var valid_603059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603059 = validateParameter(valid_603059, JString, required = false,
                                 default = nil)
  if valid_603059 != nil:
    section.add "X-Amz-SignedHeaders", valid_603059
  var valid_603060 = header.getOrDefault("X-Amz-Credential")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "X-Amz-Credential", valid_603060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603062: Call_GetProducts_603048; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all products that match the filter criteria.
  ## 
  let valid = call_603062.validator(path, query, header, formData, body)
  let scheme = call_603062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603062.url(scheme.get, call_603062.host, call_603062.base,
                         call_603062.route, valid.getOrDefault("path"))
  result = hook(call_603062, url, valid)

proc call*(call_603063: Call_GetProducts_603048; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getProducts
  ## Returns a list of all products that match the filter criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603064 = newJObject()
  var body_603065 = newJObject()
  add(query_603064, "NextToken", newJString(NextToken))
  if body != nil:
    body_603065 = body
  add(query_603064, "MaxResults", newJString(MaxResults))
  result = call_603063.call(nil, query_603064, nil, nil, body_603065)

var getProducts* = Call_GetProducts_603048(name: "getProducts",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.pricing.amazonaws.com", route: "/#X-Amz-Target=AWSPriceListService.GetProducts",
                                        validator: validate_GetProducts_603049,
                                        base: "/", url: url_GetProducts_603050,
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
