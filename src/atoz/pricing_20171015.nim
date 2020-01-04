
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

  OpenApiRestCall_601380 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601380](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601380): Option[Scheme] {.used.} =
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
  Call_DescribeServices_601718 = ref object of OpenApiRestCall_601380
proc url_DescribeServices_601720(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeServices_601719(path: JsonNode; query: JsonNode;
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
  var valid_601832 = query.getOrDefault("MaxResults")
  valid_601832 = validateParameter(valid_601832, JString, required = false,
                                 default = nil)
  if valid_601832 != nil:
    section.add "MaxResults", valid_601832
  var valid_601833 = query.getOrDefault("NextToken")
  valid_601833 = validateParameter(valid_601833, JString, required = false,
                                 default = nil)
  if valid_601833 != nil:
    section.add "NextToken", valid_601833
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601847 = header.getOrDefault("X-Amz-Target")
  valid_601847 = validateParameter(valid_601847, JString, required = true, default = newJString(
      "AWSPriceListService.DescribeServices"))
  if valid_601847 != nil:
    section.add "X-Amz-Target", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Signature")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Signature", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-Content-Sha256", valid_601849
  var valid_601850 = header.getOrDefault("X-Amz-Date")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "X-Amz-Date", valid_601850
  var valid_601851 = header.getOrDefault("X-Amz-Credential")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "X-Amz-Credential", valid_601851
  var valid_601852 = header.getOrDefault("X-Amz-Security-Token")
  valid_601852 = validateParameter(valid_601852, JString, required = false,
                                 default = nil)
  if valid_601852 != nil:
    section.add "X-Amz-Security-Token", valid_601852
  var valid_601853 = header.getOrDefault("X-Amz-Algorithm")
  valid_601853 = validateParameter(valid_601853, JString, required = false,
                                 default = nil)
  if valid_601853 != nil:
    section.add "X-Amz-Algorithm", valid_601853
  var valid_601854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601854 = validateParameter(valid_601854, JString, required = false,
                                 default = nil)
  if valid_601854 != nil:
    section.add "X-Amz-SignedHeaders", valid_601854
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601878: Call_DescribeServices_601718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the metadata for one service or a list of the metadata for all services. Use this without a service code to get the service codes for all services. Use it with a service code, such as <code>AmazonEC2</code>, to get information specific to that service, such as the attribute names available for that service. For example, some of the attribute names available for EC2 are <code>volumeType</code>, <code>maxIopsVolume</code>, <code>operation</code>, <code>locationType</code>, and <code>instanceCapacity10xlarge</code>.
  ## 
  let valid = call_601878.validator(path, query, header, formData, body)
  let scheme = call_601878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601878.url(scheme.get, call_601878.host, call_601878.base,
                         call_601878.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601878, url, valid)

proc call*(call_601949: Call_DescribeServices_601718; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeServices
  ## Returns the metadata for one service or a list of the metadata for all services. Use this without a service code to get the service codes for all services. Use it with a service code, such as <code>AmazonEC2</code>, to get information specific to that service, such as the attribute names available for that service. For example, some of the attribute names available for EC2 are <code>volumeType</code>, <code>maxIopsVolume</code>, <code>operation</code>, <code>locationType</code>, and <code>instanceCapacity10xlarge</code>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601950 = newJObject()
  var body_601952 = newJObject()
  add(query_601950, "MaxResults", newJString(MaxResults))
  add(query_601950, "NextToken", newJString(NextToken))
  if body != nil:
    body_601952 = body
  result = call_601949.call(nil, query_601950, nil, nil, body_601952)

var describeServices* = Call_DescribeServices_601718(name: "describeServices",
    meth: HttpMethod.HttpPost, host: "api.pricing.amazonaws.com",
    route: "/#X-Amz-Target=AWSPriceListService.DescribeServices",
    validator: validate_DescribeServices_601719, base: "/",
    url: url_DescribeServices_601720, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttributeValues_601991 = ref object of OpenApiRestCall_601380
proc url_GetAttributeValues_601993(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAttributeValues_601992(path: JsonNode; query: JsonNode;
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
  var valid_601994 = query.getOrDefault("MaxResults")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "MaxResults", valid_601994
  var valid_601995 = query.getOrDefault("NextToken")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "NextToken", valid_601995
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601996 = header.getOrDefault("X-Amz-Target")
  valid_601996 = validateParameter(valid_601996, JString, required = true, default = newJString(
      "AWSPriceListService.GetAttributeValues"))
  if valid_601996 != nil:
    section.add "X-Amz-Target", valid_601996
  var valid_601997 = header.getOrDefault("X-Amz-Signature")
  valid_601997 = validateParameter(valid_601997, JString, required = false,
                                 default = nil)
  if valid_601997 != nil:
    section.add "X-Amz-Signature", valid_601997
  var valid_601998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601998 = validateParameter(valid_601998, JString, required = false,
                                 default = nil)
  if valid_601998 != nil:
    section.add "X-Amz-Content-Sha256", valid_601998
  var valid_601999 = header.getOrDefault("X-Amz-Date")
  valid_601999 = validateParameter(valid_601999, JString, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "X-Amz-Date", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Credential")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Credential", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Security-Token")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Security-Token", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Algorithm")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Algorithm", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-SignedHeaders", valid_602003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602005: Call_GetAttributeValues_601991; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of attribute values. Attibutes are similar to the details in a Price List API offer file. For a list of available attributes, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/reading-an-offer.html#pps-defs">Offer File Definitions</a> in the <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/billing-what-is.html">AWS Billing and Cost Management User Guide</a>.
  ## 
  let valid = call_602005.validator(path, query, header, formData, body)
  let scheme = call_602005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602005.url(scheme.get, call_602005.host, call_602005.base,
                         call_602005.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602005, url, valid)

proc call*(call_602006: Call_GetAttributeValues_601991; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getAttributeValues
  ## Returns a list of attribute values. Attibutes are similar to the details in a Price List API offer file. For a list of available attributes, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/reading-an-offer.html#pps-defs">Offer File Definitions</a> in the <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/billing-what-is.html">AWS Billing and Cost Management User Guide</a>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602007 = newJObject()
  var body_602008 = newJObject()
  add(query_602007, "MaxResults", newJString(MaxResults))
  add(query_602007, "NextToken", newJString(NextToken))
  if body != nil:
    body_602008 = body
  result = call_602006.call(nil, query_602007, nil, nil, body_602008)

var getAttributeValues* = Call_GetAttributeValues_601991(
    name: "getAttributeValues", meth: HttpMethod.HttpPost,
    host: "api.pricing.amazonaws.com",
    route: "/#X-Amz-Target=AWSPriceListService.GetAttributeValues",
    validator: validate_GetAttributeValues_601992, base: "/",
    url: url_GetAttributeValues_601993, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProducts_602009 = ref object of OpenApiRestCall_601380
proc url_GetProducts_602011(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetProducts_602010(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602012 = query.getOrDefault("MaxResults")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "MaxResults", valid_602012
  var valid_602013 = query.getOrDefault("NextToken")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "NextToken", valid_602013
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602014 = header.getOrDefault("X-Amz-Target")
  valid_602014 = validateParameter(valid_602014, JString, required = true, default = newJString(
      "AWSPriceListService.GetProducts"))
  if valid_602014 != nil:
    section.add "X-Amz-Target", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Signature")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Signature", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Content-Sha256", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Date")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Date", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Credential")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Credential", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Security-Token")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Security-Token", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Algorithm")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Algorithm", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-SignedHeaders", valid_602021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602023: Call_GetProducts_602009; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all products that match the filter criteria.
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_GetProducts_602009; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getProducts
  ## Returns a list of all products that match the filter criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602025 = newJObject()
  var body_602026 = newJObject()
  add(query_602025, "MaxResults", newJString(MaxResults))
  add(query_602025, "NextToken", newJString(NextToken))
  if body != nil:
    body_602026 = body
  result = call_602024.call(nil, query_602025, nil, nil, body_602026)

var getProducts* = Call_GetProducts_602009(name: "getProducts",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.pricing.amazonaws.com", route: "/#X-Amz-Target=AWSPriceListService.GetProducts",
                                        validator: validate_GetProducts_602010,
                                        base: "/", url: url_GetProducts_602011,
                                        schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
