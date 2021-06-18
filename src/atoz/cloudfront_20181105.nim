
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudFront
## version: 2018-11-05
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon CloudFront</fullname> <p>This is the <i>Amazon CloudFront API Reference</i>. This guide is for developers who need detailed information about CloudFront API actions, data types, and errors. For detailed information about CloudFront features, see the <i>Amazon CloudFront Developer Guide</i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cloudfront/
type
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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
    if required:
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn", "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Http: {
      "cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "cloudfront"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateCloudFrontOriginAccessIdentity20181105_402656477 = ref object of OpenApiRestCall_402656044
proc url_CreateCloudFrontOriginAccessIdentity20181105_402656479(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCloudFrontOriginAccessIdentity20181105_402656478(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
                                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656480 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656480 = validateParameter(valid_402656480, JString,
                                      required = false, default = nil)
  if valid_402656480 != nil:
    section.add "X-Amz-Security-Token", valid_402656480
  var valid_402656481 = header.getOrDefault("X-Amz-Signature")
  valid_402656481 = validateParameter(valid_402656481, JString,
                                      required = false, default = nil)
  if valid_402656481 != nil:
    section.add "X-Amz-Signature", valid_402656481
  var valid_402656482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656482
  var valid_402656483 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656483 = validateParameter(valid_402656483, JString,
                                      required = false, default = nil)
  if valid_402656483 != nil:
    section.add "X-Amz-Algorithm", valid_402656483
  var valid_402656484 = header.getOrDefault("X-Amz-Date")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-Date", valid_402656484
  var valid_402656485 = header.getOrDefault("X-Amz-Credential")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Credential", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656488: Call_CreateCloudFrontOriginAccessIdentity20181105_402656477;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
                                                                                         ## 
  let valid = call_402656488.validator(path, query, header, formData, body, _)
  let scheme = call_402656488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656488.makeUrl(scheme.get, call_402656488.host, call_402656488.base,
                                   call_402656488.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656488, uri, valid, _)

proc call*(call_402656489: Call_CreateCloudFrontOriginAccessIdentity20181105_402656477;
           body: JsonNode): Recallable =
  ## createCloudFrontOriginAccessIdentity20181105
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656490 = newJObject()
  if body != nil:
    body_402656490 = body
  result = call_402656489.call(nil, nil, nil, nil, body_402656490)

var createCloudFrontOriginAccessIdentity20181105* = Call_CreateCloudFrontOriginAccessIdentity20181105_402656477(
    name: "createCloudFrontOriginAccessIdentity20181105",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/origin-access-identity/cloudfront",
    validator: validate_CreateCloudFrontOriginAccessIdentity20181105_402656478,
    base: "/", makeUrl: url_CreateCloudFrontOriginAccessIdentity20181105_402656479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCloudFrontOriginAccessIdentities20181105_402656294 = ref object of OpenApiRestCall_402656044
proc url_ListCloudFrontOriginAccessIdentities20181105_402656296(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCloudFrontOriginAccessIdentities20181105_402656295(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Lists origin access identities.
                                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
                                  ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                ## MaxItems: JString
                                                                                                                                                                                                                                                                                                                                                                                                                                ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## origin 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## access 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## identities 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## body. 
  section = newJObject()
  var valid_402656375 = query.getOrDefault("Marker")
  valid_402656375 = validateParameter(valid_402656375, JString,
                                      required = false, default = nil)
  if valid_402656375 != nil:
    section.add "Marker", valid_402656375
  var valid_402656376 = query.getOrDefault("MaxItems")
  valid_402656376 = validateParameter(valid_402656376, JString,
                                      required = false, default = nil)
  if valid_402656376 != nil:
    section.add "MaxItems", valid_402656376
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656377 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656377 = validateParameter(valid_402656377, JString,
                                      required = false, default = nil)
  if valid_402656377 != nil:
    section.add "X-Amz-Security-Token", valid_402656377
  var valid_402656378 = header.getOrDefault("X-Amz-Signature")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "X-Amz-Signature", valid_402656378
  var valid_402656379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656379 = validateParameter(valid_402656379, JString,
                                      required = false, default = nil)
  if valid_402656379 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656379
  var valid_402656380 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656380 = validateParameter(valid_402656380, JString,
                                      required = false, default = nil)
  if valid_402656380 != nil:
    section.add "X-Amz-Algorithm", valid_402656380
  var valid_402656381 = header.getOrDefault("X-Amz-Date")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Date", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Credential")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Credential", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656397: Call_ListCloudFrontOriginAccessIdentities20181105_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists origin access identities.
                                                                                         ## 
  let valid = call_402656397.validator(path, query, header, formData, body, _)
  let scheme = call_402656397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656397.makeUrl(scheme.get, call_402656397.host, call_402656397.base,
                                   call_402656397.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656397, uri, valid, _)

proc call*(call_402656446: Call_ListCloudFrontOriginAccessIdentities20181105_402656294;
           Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listCloudFrontOriginAccessIdentities20181105
  ## Lists origin access identities.
  ##   Marker: string
                                    ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## MaxItems: string
                                                                                                                                                                                                                                                                                                                                                                                                                                  ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## origin 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## access 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## identities 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body. 
  var query_402656447 = newJObject()
  add(query_402656447, "Marker", newJString(Marker))
  add(query_402656447, "MaxItems", newJString(MaxItems))
  result = call_402656446.call(nil, query_402656447, nil, nil, nil)

var listCloudFrontOriginAccessIdentities20181105* = Call_ListCloudFrontOriginAccessIdentities20181105_402656294(
    name: "listCloudFrontOriginAccessIdentities20181105",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/origin-access-identity/cloudfront",
    validator: validate_ListCloudFrontOriginAccessIdentities20181105_402656295,
    base: "/", makeUrl: url_ListCloudFrontOriginAccessIdentities20181105_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistribution20181105_402656506 = ref object of OpenApiRestCall_402656044
proc url_CreateDistribution20181105_402656508(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDistribution20181105_402656507(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a new web distribution. You create a CloudFront distribution to tell CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.</p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using <a>UpdateDistribution</a>, follow the steps included in the documentation to get the current configuration and then make your updates. This helps to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>If you are using Adobe Flash Media Server's RTMP protocol, you set up a different kind of CloudFront distribution. For more information, see <a>CreateStreamingDistribution</a>.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656509 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Security-Token", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Signature")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Signature", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Algorithm", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Date")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Date", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-Credential")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Credential", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656517: Call_CreateDistribution20181105_402656506;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new web distribution. You create a CloudFront distribution to tell CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.</p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using <a>UpdateDistribution</a>, follow the steps included in the documentation to get the current configuration and then make your updates. This helps to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>If you are using Adobe Flash Media Server's RTMP protocol, you set up a different kind of CloudFront distribution. For more information, see <a>CreateStreamingDistribution</a>.</p>
                                                                                         ## 
  let valid = call_402656517.validator(path, query, header, formData, body, _)
  let scheme = call_402656517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656517.makeUrl(scheme.get, call_402656517.host, call_402656517.base,
                                   call_402656517.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656517, uri, valid, _)

proc call*(call_402656518: Call_CreateDistribution20181105_402656506;
           body: JsonNode): Recallable =
  ## createDistribution20181105
  ## <p>Creates a new web distribution. You create a CloudFront distribution to tell CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.</p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using <a>UpdateDistribution</a>, follow the steps included in the documentation to get the current configuration and then make your updates. This helps to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>If you are using Adobe Flash Media Server's RTMP protocol, you set up a different kind of CloudFront distribution. For more information, see <a>CreateStreamingDistribution</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656519 = newJObject()
  if body != nil:
    body_402656519 = body
  result = call_402656518.call(nil, nil, nil, nil, body_402656519)

var createDistribution20181105* = Call_CreateDistribution20181105_402656506(
    name: "createDistribution20181105", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/distribution",
    validator: validate_CreateDistribution20181105_402656507, base: "/",
    makeUrl: url_CreateDistribution20181105_402656508,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributions20181105_402656491 = ref object of OpenApiRestCall_402656044
proc url_ListDistributions20181105_402656493(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDistributions20181105_402656492(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## List distributions. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
                                  ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                            ## MaxItems: JString
                                                                                                                                                                                                                                                                                                                                                                                                                            ##           
                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## distributions 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                            ## body.
  section = newJObject()
  var valid_402656494 = query.getOrDefault("Marker")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "Marker", valid_402656494
  var valid_402656495 = query.getOrDefault("MaxItems")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "MaxItems", valid_402656495
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656496 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Security-Token", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Signature")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Signature", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-Algorithm", valid_402656499
  var valid_402656500 = header.getOrDefault("X-Amz-Date")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-Date", valid_402656500
  var valid_402656501 = header.getOrDefault("X-Amz-Credential")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-Credential", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656503: Call_ListDistributions20181105_402656491;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List distributions. 
                                                                                         ## 
  let valid = call_402656503.validator(path, query, header, formData, body, _)
  let scheme = call_402656503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656503.makeUrl(scheme.get, call_402656503.host, call_402656503.base,
                                   call_402656503.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656503, uri, valid, _)

proc call*(call_402656504: Call_ListDistributions20181105_402656491;
           Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listDistributions20181105
  ## List distributions. 
  ##   Marker: string
                         ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                   ## MaxItems: string
                                                                                                                                                                                                                                                                                                                                                                                                                   ##           
                                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## distributions 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## body.
  var query_402656505 = newJObject()
  add(query_402656505, "Marker", newJString(Marker))
  add(query_402656505, "MaxItems", newJString(MaxItems))
  result = call_402656504.call(nil, query_402656505, nil, nil, nil)

var listDistributions20181105* = Call_ListDistributions20181105_402656491(
    name: "listDistributions20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/distribution",
    validator: validate_ListDistributions20181105_402656492, base: "/",
    makeUrl: url_ListDistributions20181105_402656493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistributionWithTags20181105_402656520 = ref object of OpenApiRestCall_402656044
proc url_CreateDistributionWithTags20181105_402656522(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDistributionWithTags20181105_402656521(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Create a new distribution with tags.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   WithTags: JBool (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `WithTags` field"
  var valid_402656523 = query.getOrDefault("WithTags")
  valid_402656523 = validateParameter(valid_402656523, JBool, required = true,
                                      default = nil)
  if valid_402656523 != nil:
    section.add "WithTags", valid_402656523
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656524 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Security-Token", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Signature")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Signature", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Algorithm", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Date")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Date", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-Credential")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Credential", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656532: Call_CreateDistributionWithTags20181105_402656520;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new distribution with tags.
                                                                                         ## 
  let valid = call_402656532.validator(path, query, header, formData, body, _)
  let scheme = call_402656532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656532.makeUrl(scheme.get, call_402656532.host, call_402656532.base,
                                   call_402656532.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656532, uri, valid, _)

proc call*(call_402656533: Call_CreateDistributionWithTags20181105_402656520;
           WithTags: bool; body: JsonNode): Recallable =
  ## createDistributionWithTags20181105
  ## Create a new distribution with tags.
  ##   WithTags: bool (required)
  ##   body: JObject (required)
  var query_402656534 = newJObject()
  var body_402656535 = newJObject()
  add(query_402656534, "WithTags", newJBool(WithTags))
  if body != nil:
    body_402656535 = body
  result = call_402656533.call(nil, query_402656534, nil, nil, body_402656535)

var createDistributionWithTags20181105* = Call_CreateDistributionWithTags20181105_402656520(
    name: "createDistributionWithTags20181105", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/distribution#WithTags",
    validator: validate_CreateDistributionWithTags20181105_402656521, base: "/",
    makeUrl: url_CreateDistributionWithTags20181105_402656522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFieldLevelEncryptionConfig20181105_402656551 = ref object of OpenApiRestCall_402656044
proc url_CreateFieldLevelEncryptionConfig20181105_402656553(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFieldLevelEncryptionConfig20181105_402656552(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Create a new field-level encryption configuration.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656554 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Security-Token", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Signature")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Signature", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Algorithm", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Date")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Date", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-Credential")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Credential", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656562: Call_CreateFieldLevelEncryptionConfig20181105_402656551;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new field-level encryption configuration.
                                                                                         ## 
  let valid = call_402656562.validator(path, query, header, formData, body, _)
  let scheme = call_402656562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656562.makeUrl(scheme.get, call_402656562.host, call_402656562.base,
                                   call_402656562.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656562, uri, valid, _)

proc call*(call_402656563: Call_CreateFieldLevelEncryptionConfig20181105_402656551;
           body: JsonNode): Recallable =
  ## createFieldLevelEncryptionConfig20181105
  ## Create a new field-level encryption configuration.
  ##   body: JObject (required)
  var body_402656564 = newJObject()
  if body != nil:
    body_402656564 = body
  result = call_402656563.call(nil, nil, nil, nil, body_402656564)

var createFieldLevelEncryptionConfig20181105* = Call_CreateFieldLevelEncryptionConfig20181105_402656551(
    name: "createFieldLevelEncryptionConfig20181105", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption",
    validator: validate_CreateFieldLevelEncryptionConfig20181105_402656552,
    base: "/", makeUrl: url_CreateFieldLevelEncryptionConfig20181105_402656553,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFieldLevelEncryptionConfigs20181105_402656536 = ref object of OpenApiRestCall_402656044
proc url_ListFieldLevelEncryptionConfigs20181105_402656538(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFieldLevelEncryptionConfigs20181105_402656537(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## List all field-level encryption configurations that have been created in CloudFront for this account.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
                                  ##         : Use this when paginating results to indicate where to begin in your list of configurations. The results include configurations in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last configuration on that page). 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                ## MaxItems: JString
                                                                                                                                                                                                                                                                                                                                                                                                                                ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## field-level 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## encryption 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## configurations 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                                ## body. 
  section = newJObject()
  var valid_402656539 = query.getOrDefault("Marker")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "Marker", valid_402656539
  var valid_402656540 = query.getOrDefault("MaxItems")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "MaxItems", valid_402656540
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656541 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Security-Token", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Signature")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Signature", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Algorithm", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Date")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Date", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-Credential")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Credential", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656548: Call_ListFieldLevelEncryptionConfigs20181105_402656536;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List all field-level encryption configurations that have been created in CloudFront for this account.
                                                                                         ## 
  let valid = call_402656548.validator(path, query, header, formData, body, _)
  let scheme = call_402656548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656548.makeUrl(scheme.get, call_402656548.host, call_402656548.base,
                                   call_402656548.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656548, uri, valid, _)

proc call*(call_402656549: Call_ListFieldLevelEncryptionConfigs20181105_402656536;
           Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listFieldLevelEncryptionConfigs20181105
  ## List all field-level encryption configurations that have been created in CloudFront for this account.
  ##   
                                                                                                          ## Marker: string
                                                                                                          ##         
                                                                                                          ## : 
                                                                                                          ## Use 
                                                                                                          ## this 
                                                                                                          ## when 
                                                                                                          ## paginating 
                                                                                                          ## results 
                                                                                                          ## to 
                                                                                                          ## indicate 
                                                                                                          ## where 
                                                                                                          ## to 
                                                                                                          ## begin 
                                                                                                          ## in 
                                                                                                          ## your 
                                                                                                          ## list 
                                                                                                          ## of 
                                                                                                          ## configurations. 
                                                                                                          ## The 
                                                                                                          ## results 
                                                                                                          ## include 
                                                                                                          ## configurations 
                                                                                                          ## in 
                                                                                                          ## the 
                                                                                                          ## list 
                                                                                                          ## that 
                                                                                                          ## occur 
                                                                                                          ## after 
                                                                                                          ## the 
                                                                                                          ## marker. 
                                                                                                          ## To 
                                                                                                          ## get 
                                                                                                          ## the 
                                                                                                          ## next 
                                                                                                          ## page 
                                                                                                          ## of 
                                                                                                          ## results, 
                                                                                                          ## set 
                                                                                                          ## the 
                                                                                                          ## <code>Marker</code> 
                                                                                                          ## to 
                                                                                                          ## the 
                                                                                                          ## value 
                                                                                                          ## of 
                                                                                                          ## the 
                                                                                                          ## <code>NextMarker</code> 
                                                                                                          ## from 
                                                                                                          ## the 
                                                                                                          ## current 
                                                                                                          ## page's 
                                                                                                          ## response 
                                                                                                          ## (which 
                                                                                                          ## is 
                                                                                                          ## also 
                                                                                                          ## the 
                                                                                                          ## ID 
                                                                                                          ## of 
                                                                                                          ## the 
                                                                                                          ## last 
                                                                                                          ## configuration 
                                                                                                          ## on 
                                                                                                          ## that 
                                                                                                          ## page). 
  ##   
                                                                                                                    ## MaxItems: string
                                                                                                                    ##           
                                                                                                                    ## : 
                                                                                                                    ## The 
                                                                                                                    ## maximum 
                                                                                                                    ## number 
                                                                                                                    ## of 
                                                                                                                    ## field-level 
                                                                                                                    ## encryption 
                                                                                                                    ## configurations 
                                                                                                                    ## you 
                                                                                                                    ## want 
                                                                                                                    ## in 
                                                                                                                    ## the 
                                                                                                                    ## response 
                                                                                                                    ## body. 
  var query_402656550 = newJObject()
  add(query_402656550, "Marker", newJString(Marker))
  add(query_402656550, "MaxItems", newJString(MaxItems))
  result = call_402656549.call(nil, query_402656550, nil, nil, nil)

var listFieldLevelEncryptionConfigs20181105* = Call_ListFieldLevelEncryptionConfigs20181105_402656536(
    name: "listFieldLevelEncryptionConfigs20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption",
    validator: validate_ListFieldLevelEncryptionConfigs20181105_402656537,
    base: "/", makeUrl: url_ListFieldLevelEncryptionConfigs20181105_402656538,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFieldLevelEncryptionProfile20181105_402656580 = ref object of OpenApiRestCall_402656044
proc url_CreateFieldLevelEncryptionProfile20181105_402656582(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFieldLevelEncryptionProfile20181105_402656581(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Create a field-level encryption profile.
                                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656583 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Security-Token", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Signature")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Signature", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Algorithm", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Date")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Date", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Credential")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Credential", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656591: Call_CreateFieldLevelEncryptionProfile20181105_402656580;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a field-level encryption profile.
                                                                                         ## 
  let valid = call_402656591.validator(path, query, header, formData, body, _)
  let scheme = call_402656591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656591.makeUrl(scheme.get, call_402656591.host, call_402656591.base,
                                   call_402656591.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656591, uri, valid, _)

proc call*(call_402656592: Call_CreateFieldLevelEncryptionProfile20181105_402656580;
           body: JsonNode): Recallable =
  ## createFieldLevelEncryptionProfile20181105
  ## Create a field-level encryption profile.
  ##   body: JObject (required)
  var body_402656593 = newJObject()
  if body != nil:
    body_402656593 = body
  result = call_402656592.call(nil, nil, nil, nil, body_402656593)

var createFieldLevelEncryptionProfile20181105* = Call_CreateFieldLevelEncryptionProfile20181105_402656580(
    name: "createFieldLevelEncryptionProfile20181105",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption-profile",
    validator: validate_CreateFieldLevelEncryptionProfile20181105_402656581,
    base: "/", makeUrl: url_CreateFieldLevelEncryptionProfile20181105_402656582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFieldLevelEncryptionProfiles20181105_402656565 = ref object of OpenApiRestCall_402656044
proc url_ListFieldLevelEncryptionProfiles20181105_402656567(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFieldLevelEncryptionProfiles20181105_402656566(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Request a list of field-level encryption profiles that have been created in CloudFront for this account.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
                                  ##         : Use this when paginating results to indicate where to begin in your list of profiles. The results include profiles in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last profile on that page). 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                              ## MaxItems: JString
                                                                                                                                                                                                                                                                                                                                                                                                              ##           
                                                                                                                                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                                                                                                                                                                                              ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                              ## number 
                                                                                                                                                                                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                                                                                                                                                                                              ## field-level 
                                                                                                                                                                                                                                                                                                                                                                                                              ## encryption 
                                                                                                                                                                                                                                                                                                                                                                                                              ## profiles 
                                                                                                                                                                                                                                                                                                                                                                                                              ## you 
                                                                                                                                                                                                                                                                                                                                                                                                              ## want 
                                                                                                                                                                                                                                                                                                                                                                                                              ## in 
                                                                                                                                                                                                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                                                                                                                                                                                                              ## response 
                                                                                                                                                                                                                                                                                                                                                                                                              ## body. 
  section = newJObject()
  var valid_402656568 = query.getOrDefault("Marker")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "Marker", valid_402656568
  var valid_402656569 = query.getOrDefault("MaxItems")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "MaxItems", valid_402656569
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656570 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Security-Token", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Signature")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Signature", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Algorithm", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-Date")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Date", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Credential")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Credential", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656577: Call_ListFieldLevelEncryptionProfiles20181105_402656565;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Request a list of field-level encryption profiles that have been created in CloudFront for this account.
                                                                                         ## 
  let valid = call_402656577.validator(path, query, header, formData, body, _)
  let scheme = call_402656577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656577.makeUrl(scheme.get, call_402656577.host, call_402656577.base,
                                   call_402656577.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656577, uri, valid, _)

proc call*(call_402656578: Call_ListFieldLevelEncryptionProfiles20181105_402656565;
           Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listFieldLevelEncryptionProfiles20181105
  ## Request a list of field-level encryption profiles that have been created in CloudFront for this account.
  ##   
                                                                                                             ## Marker: string
                                                                                                             ##         
                                                                                                             ## : 
                                                                                                             ## Use 
                                                                                                             ## this 
                                                                                                             ## when 
                                                                                                             ## paginating 
                                                                                                             ## results 
                                                                                                             ## to 
                                                                                                             ## indicate 
                                                                                                             ## where 
                                                                                                             ## to 
                                                                                                             ## begin 
                                                                                                             ## in 
                                                                                                             ## your 
                                                                                                             ## list 
                                                                                                             ## of 
                                                                                                             ## profiles. 
                                                                                                             ## The 
                                                                                                             ## results 
                                                                                                             ## include 
                                                                                                             ## profiles 
                                                                                                             ## in 
                                                                                                             ## the 
                                                                                                             ## list 
                                                                                                             ## that 
                                                                                                             ## occur 
                                                                                                             ## after 
                                                                                                             ## the 
                                                                                                             ## marker. 
                                                                                                             ## To 
                                                                                                             ## get 
                                                                                                             ## the 
                                                                                                             ## next 
                                                                                                             ## page 
                                                                                                             ## of 
                                                                                                             ## results, 
                                                                                                             ## set 
                                                                                                             ## the 
                                                                                                             ## <code>Marker</code> 
                                                                                                             ## to 
                                                                                                             ## the 
                                                                                                             ## value 
                                                                                                             ## of 
                                                                                                             ## the 
                                                                                                             ## <code>NextMarker</code> 
                                                                                                             ## from 
                                                                                                             ## the 
                                                                                                             ## current 
                                                                                                             ## page's 
                                                                                                             ## response 
                                                                                                             ## (which 
                                                                                                             ## is 
                                                                                                             ## also 
                                                                                                             ## the 
                                                                                                             ## ID 
                                                                                                             ## of 
                                                                                                             ## the 
                                                                                                             ## last 
                                                                                                             ## profile 
                                                                                                             ## on 
                                                                                                             ## that 
                                                                                                             ## page). 
  ##   
                                                                                                                       ## MaxItems: string
                                                                                                                       ##           
                                                                                                                       ## : 
                                                                                                                       ## The 
                                                                                                                       ## maximum 
                                                                                                                       ## number 
                                                                                                                       ## of 
                                                                                                                       ## field-level 
                                                                                                                       ## encryption 
                                                                                                                       ## profiles 
                                                                                                                       ## you 
                                                                                                                       ## want 
                                                                                                                       ## in 
                                                                                                                       ## the 
                                                                                                                       ## response 
                                                                                                                       ## body. 
  var query_402656579 = newJObject()
  add(query_402656579, "Marker", newJString(Marker))
  add(query_402656579, "MaxItems", newJString(MaxItems))
  result = call_402656578.call(nil, query_402656579, nil, nil, nil)

var listFieldLevelEncryptionProfiles20181105* = Call_ListFieldLevelEncryptionProfiles20181105_402656565(
    name: "listFieldLevelEncryptionProfiles20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption-profile",
    validator: validate_ListFieldLevelEncryptionProfiles20181105_402656566,
    base: "/", makeUrl: url_ListFieldLevelEncryptionProfiles20181105_402656567,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInvalidation20181105_402656622 = ref object of OpenApiRestCall_402656044
proc url_CreateInvalidation20181105_402656624(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path,
         "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/distribution/"),
                 (kind: VariableSegment, value: "DistributionId"),
                 (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateInvalidation20181105_402656623(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Create a new invalidation. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
                                 ##                 : The distribution's id.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DistributionId` field"
  var valid_402656625 = path.getOrDefault("DistributionId")
  valid_402656625 = validateParameter(valid_402656625, JString, required = true,
                                      default = nil)
  if valid_402656625 != nil:
    section.add "DistributionId", valid_402656625
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656626 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-Security-Token", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-Signature")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-Signature", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Algorithm", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Date")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Date", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Credential")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Credential", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656634: Call_CreateInvalidation20181105_402656622;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new invalidation. 
                                                                                         ## 
  let valid = call_402656634.validator(path, query, header, formData, body, _)
  let scheme = call_402656634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656634.makeUrl(scheme.get, call_402656634.host, call_402656634.base,
                                   call_402656634.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656634, uri, valid, _)

proc call*(call_402656635: Call_CreateInvalidation20181105_402656622;
           DistributionId: string; body: JsonNode): Recallable =
  ## createInvalidation20181105
  ## Create a new invalidation. 
  ##   DistributionId: string (required)
                                ##                 : The distribution's id.
  ##   body: 
                                                                           ## JObject (required)
  var path_402656636 = newJObject()
  var body_402656637 = newJObject()
  add(path_402656636, "DistributionId", newJString(DistributionId))
  if body != nil:
    body_402656637 = body
  result = call_402656635.call(path_402656636, nil, nil, nil, body_402656637)

var createInvalidation20181105* = Call_CreateInvalidation20181105_402656622(
    name: "createInvalidation20181105", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/distribution/{DistributionId}/invalidation",
    validator: validate_CreateInvalidation20181105_402656623, base: "/",
    makeUrl: url_CreateInvalidation20181105_402656624,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvalidations20181105_402656594 = ref object of OpenApiRestCall_402656044
proc url_ListInvalidations20181105_402656596(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path,
         "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/distribution/"),
                 (kind: VariableSegment, value: "DistributionId"),
                 (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListInvalidations20181105_402656595(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists invalidation batches. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
                                 ##                 : The distribution's ID.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DistributionId` field"
  var valid_402656608 = path.getOrDefault("DistributionId")
  valid_402656608 = validateParameter(valid_402656608, JString, required = true,
                                      default = nil)
  if valid_402656608 != nil:
    section.add "DistributionId", valid_402656608
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
                                  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## MaxItems: JString
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## invalidation 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## batches 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## body.
  section = newJObject()
  var valid_402656609 = query.getOrDefault("Marker")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "Marker", valid_402656609
  var valid_402656610 = query.getOrDefault("MaxItems")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "MaxItems", valid_402656610
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656611 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Security-Token", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-Signature")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Signature", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Algorithm", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Date")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Date", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Credential")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Credential", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656618: Call_ListInvalidations20181105_402656594;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists invalidation batches. 
                                                                                         ## 
  let valid = call_402656618.validator(path, query, header, formData, body, _)
  let scheme = call_402656618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656618.makeUrl(scheme.get, call_402656618.host, call_402656618.base,
                                   call_402656618.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656618, uri, valid, _)

proc call*(call_402656619: Call_ListInvalidations20181105_402656594;
           DistributionId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listInvalidations20181105
  ## Lists invalidation batches. 
  ##   DistributionId: string (required)
                                 ##                 : The distribution's ID.
  ##   
                                                                            ## Marker: string
                                                                            ##         
                                                                            ## : 
                                                                            ## Use 
                                                                            ## this 
                                                                            ## parameter 
                                                                            ## when 
                                                                            ## paginating 
                                                                            ## results 
                                                                            ## to 
                                                                            ## indicate 
                                                                            ## where 
                                                                            ## to 
                                                                            ## begin 
                                                                            ## in 
                                                                            ## your 
                                                                            ## list 
                                                                            ## of 
                                                                            ## invalidation 
                                                                            ## batches. 
                                                                            ## Because 
                                                                            ## the 
                                                                            ## results 
                                                                            ## are 
                                                                            ## returned 
                                                                            ## in 
                                                                            ## decreasing 
                                                                            ## order 
                                                                            ## from 
                                                                            ## most 
                                                                            ## recent 
                                                                            ## to 
                                                                            ## oldest, 
                                                                            ## the 
                                                                            ## most 
                                                                            ## recent 
                                                                            ## results 
                                                                            ## are 
                                                                            ## on 
                                                                            ## the 
                                                                            ## first 
                                                                            ## page, 
                                                                            ## the 
                                                                            ## second 
                                                                            ## page 
                                                                            ## will 
                                                                            ## contain 
                                                                            ## earlier 
                                                                            ## results, 
                                                                            ## and 
                                                                            ## so 
                                                                            ## on. 
                                                                            ## To 
                                                                            ## get 
                                                                            ## the 
                                                                            ## next 
                                                                            ## page 
                                                                            ## of 
                                                                            ## results, 
                                                                            ## set 
                                                                            ## <code>Marker</code> 
                                                                            ## to 
                                                                            ## the 
                                                                            ## value 
                                                                            ## of 
                                                                            ## the 
                                                                            ## <code>NextMarker</code> 
                                                                            ## from 
                                                                            ## the 
                                                                            ## current 
                                                                            ## page's 
                                                                            ## response. 
                                                                            ## This 
                                                                            ## value 
                                                                            ## is 
                                                                            ## the 
                                                                            ## same 
                                                                            ## as 
                                                                            ## the 
                                                                            ## ID 
                                                                            ## of 
                                                                            ## the 
                                                                            ## last 
                                                                            ## invalidation 
                                                                            ## batch 
                                                                            ## on 
                                                                            ## that 
                                                                            ## page. 
  ##   
                                                                                     ## MaxItems: string
                                                                                     ##           
                                                                                     ## : 
                                                                                     ## The 
                                                                                     ## maximum 
                                                                                     ## number 
                                                                                     ## of 
                                                                                     ## invalidation 
                                                                                     ## batches 
                                                                                     ## that 
                                                                                     ## you 
                                                                                     ## want 
                                                                                     ## in 
                                                                                     ## the 
                                                                                     ## response 
                                                                                     ## body.
  var path_402656620 = newJObject()
  var query_402656621 = newJObject()
  add(path_402656620, "DistributionId", newJString(DistributionId))
  add(query_402656621, "Marker", newJString(Marker))
  add(query_402656621, "MaxItems", newJString(MaxItems))
  result = call_402656619.call(path_402656620, query_402656621, nil, nil, nil)

var listInvalidations20181105* = Call_ListInvalidations20181105_402656594(
    name: "listInvalidations20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/distribution/{DistributionId}/invalidation",
    validator: validate_ListInvalidations20181105_402656595, base: "/",
    makeUrl: url_ListInvalidations20181105_402656596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePublicKey20181105_402656653 = ref object of OpenApiRestCall_402656044
proc url_CreatePublicKey20181105_402656655(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePublicKey20181105_402656654(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Add a new public key to CloudFront to use, for example, for field-level encryption. You can add a maximum of 10 public keys with one AWS account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656656 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656656 = validateParameter(valid_402656656, JString,
                                      required = false, default = nil)
  if valid_402656656 != nil:
    section.add "X-Amz-Security-Token", valid_402656656
  var valid_402656657 = header.getOrDefault("X-Amz-Signature")
  valid_402656657 = validateParameter(valid_402656657, JString,
                                      required = false, default = nil)
  if valid_402656657 != nil:
    section.add "X-Amz-Signature", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Algorithm", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Date")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Date", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Credential")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Credential", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656664: Call_CreatePublicKey20181105_402656653;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Add a new public key to CloudFront to use, for example, for field-level encryption. You can add a maximum of 10 public keys with one AWS account.
                                                                                         ## 
  let valid = call_402656664.validator(path, query, header, formData, body, _)
  let scheme = call_402656664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656664.makeUrl(scheme.get, call_402656664.host, call_402656664.base,
                                   call_402656664.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656664, uri, valid, _)

proc call*(call_402656665: Call_CreatePublicKey20181105_402656653;
           body: JsonNode): Recallable =
  ## createPublicKey20181105
  ## Add a new public key to CloudFront to use, for example, for field-level encryption. You can add a maximum of 10 public keys with one AWS account.
  ##   
                                                                                                                                                      ## body: JObject (required)
  var body_402656666 = newJObject()
  if body != nil:
    body_402656666 = body
  result = call_402656665.call(nil, nil, nil, nil, body_402656666)

var createPublicKey20181105* = Call_CreatePublicKey20181105_402656653(
    name: "createPublicKey20181105", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/public-key",
    validator: validate_CreatePublicKey20181105_402656654, base: "/",
    makeUrl: url_CreatePublicKey20181105_402656655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublicKeys20181105_402656638 = ref object of OpenApiRestCall_402656044
proc url_ListPublicKeys20181105_402656640(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPublicKeys20181105_402656639(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List all public keys that have been added to CloudFront for this account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
                                  ##         : Use this when paginating results to indicate where to begin in your list of public keys. The results include public keys in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last public key on that page). 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                       ## MaxItems: JString
                                                                                                                                                                                                                                                                                                                                                                                                                       ##           
                                                                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## public 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## keys 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                       ## body. 
  section = newJObject()
  var valid_402656641 = query.getOrDefault("Marker")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "Marker", valid_402656641
  var valid_402656642 = query.getOrDefault("MaxItems")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "MaxItems", valid_402656642
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656643 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Security-Token", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Signature")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Signature", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Algorithm", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Date")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Date", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Credential")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Credential", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656650: Call_ListPublicKeys20181105_402656638;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List all public keys that have been added to CloudFront for this account.
                                                                                         ## 
  let valid = call_402656650.validator(path, query, header, formData, body, _)
  let scheme = call_402656650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656650.makeUrl(scheme.get, call_402656650.host, call_402656650.base,
                                   call_402656650.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656650, uri, valid, _)

proc call*(call_402656651: Call_ListPublicKeys20181105_402656638;
           Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listPublicKeys20181105
  ## List all public keys that have been added to CloudFront for this account.
  ##   
                                                                              ## Marker: string
                                                                              ##         
                                                                              ## : 
                                                                              ## Use 
                                                                              ## this 
                                                                              ## when 
                                                                              ## paginating 
                                                                              ## results 
                                                                              ## to 
                                                                              ## indicate 
                                                                              ## where 
                                                                              ## to 
                                                                              ## begin 
                                                                              ## in 
                                                                              ## your 
                                                                              ## list 
                                                                              ## of 
                                                                              ## public 
                                                                              ## keys. 
                                                                              ## The 
                                                                              ## results 
                                                                              ## include 
                                                                              ## public 
                                                                              ## keys 
                                                                              ## in 
                                                                              ## the 
                                                                              ## list 
                                                                              ## that 
                                                                              ## occur 
                                                                              ## after 
                                                                              ## the 
                                                                              ## marker. 
                                                                              ## To 
                                                                              ## get 
                                                                              ## the 
                                                                              ## next 
                                                                              ## page 
                                                                              ## of 
                                                                              ## results, 
                                                                              ## set 
                                                                              ## the 
                                                                              ## <code>Marker</code> 
                                                                              ## to 
                                                                              ## the 
                                                                              ## value 
                                                                              ## of 
                                                                              ## the 
                                                                              ## <code>NextMarker</code> 
                                                                              ## from 
                                                                              ## the 
                                                                              ## current 
                                                                              ## page's 
                                                                              ## response 
                                                                              ## (which 
                                                                              ## is 
                                                                              ## also 
                                                                              ## the 
                                                                              ## ID 
                                                                              ## of 
                                                                              ## the 
                                                                              ## last 
                                                                              ## public 
                                                                              ## key 
                                                                              ## on 
                                                                              ## that 
                                                                              ## page). 
  ##   
                                                                                        ## MaxItems: string
                                                                                        ##           
                                                                                        ## : 
                                                                                        ## The 
                                                                                        ## maximum 
                                                                                        ## number 
                                                                                        ## of 
                                                                                        ## public 
                                                                                        ## keys 
                                                                                        ## you 
                                                                                        ## want 
                                                                                        ## in 
                                                                                        ## the 
                                                                                        ## response 
                                                                                        ## body. 
  var query_402656652 = newJObject()
  add(query_402656652, "Marker", newJString(Marker))
  add(query_402656652, "MaxItems", newJString(MaxItems))
  result = call_402656651.call(nil, query_402656652, nil, nil, nil)

var listPublicKeys20181105* = Call_ListPublicKeys20181105_402656638(
    name: "listPublicKeys20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/public-key",
    validator: validate_ListPublicKeys20181105_402656639, base: "/",
    makeUrl: url_ListPublicKeys20181105_402656640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistribution20181105_402656682 = ref object of OpenApiRestCall_402656044
proc url_CreateStreamingDistribution20181105_402656684(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStreamingDistribution20181105_402656683(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656685 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-Security-Token", valid_402656685
  var valid_402656686 = header.getOrDefault("X-Amz-Signature")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "X-Amz-Signature", valid_402656686
  var valid_402656687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Algorithm", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Date")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Date", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Credential")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Credential", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656691
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656693: Call_CreateStreamingDistribution20181105_402656682;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
                                                                                         ## 
  let valid = call_402656693.validator(path, query, header, formData, body, _)
  let scheme = call_402656693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656693.makeUrl(scheme.get, call_402656693.host, call_402656693.base,
                                   call_402656693.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656693, uri, valid, _)

proc call*(call_402656694: Call_CreateStreamingDistribution20181105_402656682;
           body: JsonNode): Recallable =
  ## createStreamingDistribution20181105
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402656695 = newJObject()
  if body != nil:
    body_402656695 = body
  result = call_402656694.call(nil, nil, nil, nil, body_402656695)

var createStreamingDistribution20181105* = Call_CreateStreamingDistribution20181105_402656682(
    name: "createStreamingDistribution20181105", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/streaming-distribution",
    validator: validate_CreateStreamingDistribution20181105_402656683,
    base: "/", makeUrl: url_CreateStreamingDistribution20181105_402656684,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStreamingDistributions20181105_402656667 = ref object of OpenApiRestCall_402656044
proc url_ListStreamingDistributions20181105_402656669(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListStreamingDistributions20181105_402656668(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## List streaming distributions. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
                                  ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   
                                                                                                                         ## MaxItems: JString
                                                                                                                         ##           
                                                                                                                         ## : 
                                                                                                                         ## The 
                                                                                                                         ## value 
                                                                                                                         ## that 
                                                                                                                         ## you 
                                                                                                                         ## provided 
                                                                                                                         ## for 
                                                                                                                         ## the 
                                                                                                                         ## <code>MaxItems</code> 
                                                                                                                         ## request 
                                                                                                                         ## parameter.
  section = newJObject()
  var valid_402656670 = query.getOrDefault("Marker")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "Marker", valid_402656670
  var valid_402656671 = query.getOrDefault("MaxItems")
  valid_402656671 = validateParameter(valid_402656671, JString,
                                      required = false, default = nil)
  if valid_402656671 != nil:
    section.add "MaxItems", valid_402656671
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656672 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-Security-Token", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Signature")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Signature", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Algorithm", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Date")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Date", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Credential")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Credential", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656679: Call_ListStreamingDistributions20181105_402656667;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List streaming distributions. 
                                                                                         ## 
  let valid = call_402656679.validator(path, query, header, formData, body, _)
  let scheme = call_402656679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656679.makeUrl(scheme.get, call_402656679.host, call_402656679.base,
                                   call_402656679.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656679, uri, valid, _)

proc call*(call_402656680: Call_ListStreamingDistributions20181105_402656667;
           Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listStreamingDistributions20181105
  ## List streaming distributions. 
  ##   Marker: string
                                   ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   
                                                                                                                          ## MaxItems: string
                                                                                                                          ##           
                                                                                                                          ## : 
                                                                                                                          ## The 
                                                                                                                          ## value 
                                                                                                                          ## that 
                                                                                                                          ## you 
                                                                                                                          ## provided 
                                                                                                                          ## for 
                                                                                                                          ## the 
                                                                                                                          ## <code>MaxItems</code> 
                                                                                                                          ## request 
                                                                                                                          ## parameter.
  var query_402656681 = newJObject()
  add(query_402656681, "Marker", newJString(Marker))
  add(query_402656681, "MaxItems", newJString(MaxItems))
  result = call_402656680.call(nil, query_402656681, nil, nil, nil)

var listStreamingDistributions20181105* = Call_ListStreamingDistributions20181105_402656667(
    name: "listStreamingDistributions20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/streaming-distribution",
    validator: validate_ListStreamingDistributions20181105_402656668, base: "/",
    makeUrl: url_ListStreamingDistributions20181105_402656669,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistributionWithTags20181105_402656696 = ref object of OpenApiRestCall_402656044
proc url_CreateStreamingDistributionWithTags20181105_402656698(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStreamingDistributionWithTags20181105_402656697(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Create a new streaming distribution with tags.
                                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   WithTags: JBool (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `WithTags` field"
  var valid_402656699 = query.getOrDefault("WithTags")
  valid_402656699 = validateParameter(valid_402656699, JBool, required = true,
                                      default = nil)
  if valid_402656699 != nil:
    section.add "WithTags", valid_402656699
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656700 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "X-Amz-Security-Token", valid_402656700
  var valid_402656701 = header.getOrDefault("X-Amz-Signature")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-Signature", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Algorithm", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Date")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Date", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Credential")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Credential", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656706
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656708: Call_CreateStreamingDistributionWithTags20181105_402656696;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new streaming distribution with tags.
                                                                                         ## 
  let valid = call_402656708.validator(path, query, header, formData, body, _)
  let scheme = call_402656708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656708.makeUrl(scheme.get, call_402656708.host, call_402656708.base,
                                   call_402656708.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656708, uri, valid, _)

proc call*(call_402656709: Call_CreateStreamingDistributionWithTags20181105_402656696;
           WithTags: bool; body: JsonNode): Recallable =
  ## createStreamingDistributionWithTags20181105
  ## Create a new streaming distribution with tags.
  ##   WithTags: bool (required)
  ##   body: JObject (required)
  var query_402656710 = newJObject()
  var body_402656711 = newJObject()
  add(query_402656710, "WithTags", newJBool(WithTags))
  if body != nil:
    body_402656711 = body
  result = call_402656709.call(nil, query_402656710, nil, nil, body_402656711)

var createStreamingDistributionWithTags20181105* = Call_CreateStreamingDistributionWithTags20181105_402656696(
    name: "createStreamingDistributionWithTags20181105",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/streaming-distribution#WithTags",
    validator: validate_CreateStreamingDistributionWithTags20181105_402656697,
    base: "/", makeUrl: url_CreateStreamingDistributionWithTags20181105_402656698,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentity20181105_402656712 = ref object of OpenApiRestCall_402656044
proc url_GetCloudFrontOriginAccessIdentity20181105_402656714(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2018-11-05/origin-access-identity/cloudfront/"),
                 (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCloudFrontOriginAccessIdentity20181105_402656713(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Get the information about an origin access identity. 
                                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The identity's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656715 = path.getOrDefault("Id")
  valid_402656715 = validateParameter(valid_402656715, JString, required = true,
                                      default = nil)
  if valid_402656715 != nil:
    section.add "Id", valid_402656715
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656716 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656716 = validateParameter(valid_402656716, JString,
                                      required = false, default = nil)
  if valid_402656716 != nil:
    section.add "X-Amz-Security-Token", valid_402656716
  var valid_402656717 = header.getOrDefault("X-Amz-Signature")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "X-Amz-Signature", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Algorithm", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Date")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Date", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Credential")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Credential", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656722
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656723: Call_GetCloudFrontOriginAccessIdentity20181105_402656712;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the information about an origin access identity. 
                                                                                         ## 
  let valid = call_402656723.validator(path, query, header, formData, body, _)
  let scheme = call_402656723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656723.makeUrl(scheme.get, call_402656723.host, call_402656723.base,
                                   call_402656723.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656723, uri, valid, _)

proc call*(call_402656724: Call_GetCloudFrontOriginAccessIdentity20181105_402656712;
           Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentity20181105
  ## Get the information about an origin access identity. 
  ##   Id: string (required)
                                                          ##     : The identity's ID.
  var path_402656725 = newJObject()
  add(path_402656725, "Id", newJString(Id))
  result = call_402656724.call(path_402656725, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentity20181105* = Call_GetCloudFrontOriginAccessIdentity20181105_402656712(
    name: "getCloudFrontOriginAccessIdentity20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/origin-access-identity/cloudfront/{Id}",
    validator: validate_GetCloudFrontOriginAccessIdentity20181105_402656713,
    base: "/", makeUrl: url_GetCloudFrontOriginAccessIdentity20181105_402656714,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCloudFrontOriginAccessIdentity20181105_402656726 = ref object of OpenApiRestCall_402656044
proc url_DeleteCloudFrontOriginAccessIdentity20181105_402656728(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2018-11-05/origin-access-identity/cloudfront/"),
                 (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCloudFrontOriginAccessIdentity20181105_402656727(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Delete an origin access identity. 
                                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The origin access identity's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656729 = path.getOrDefault("Id")
  valid_402656729 = validateParameter(valid_402656729, JString, required = true,
                                      default = nil)
  if valid_402656729 != nil:
    section.add "Id", valid_402656729
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   If-Match: JString
                               ##           : The value of the <code>ETag</code> header you received from a previous <code>GET</code> or <code>PUT</code> request. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   
                                                                                                                                                                                                            ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                            ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                       ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                             ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                         ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656730 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656730 = validateParameter(valid_402656730, JString,
                                      required = false, default = nil)
  if valid_402656730 != nil:
    section.add "X-Amz-Security-Token", valid_402656730
  var valid_402656731 = header.getOrDefault("X-Amz-Signature")
  valid_402656731 = validateParameter(valid_402656731, JString,
                                      required = false, default = nil)
  if valid_402656731 != nil:
    section.add "X-Amz-Signature", valid_402656731
  var valid_402656732 = header.getOrDefault("If-Match")
  valid_402656732 = validateParameter(valid_402656732, JString,
                                      required = false, default = nil)
  if valid_402656732 != nil:
    section.add "If-Match", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Algorithm", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Date")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Date", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Credential")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Credential", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656737
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656738: Call_DeleteCloudFrontOriginAccessIdentity20181105_402656726;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete an origin access identity. 
                                                                                         ## 
  let valid = call_402656738.validator(path, query, header, formData, body, _)
  let scheme = call_402656738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656738.makeUrl(scheme.get, call_402656738.host, call_402656738.base,
                                   call_402656738.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656738, uri, valid, _)

proc call*(call_402656739: Call_DeleteCloudFrontOriginAccessIdentity20181105_402656726;
           Id: string): Recallable =
  ## deleteCloudFrontOriginAccessIdentity20181105
  ## Delete an origin access identity. 
  ##   Id: string (required)
                                       ##     : The origin access identity's ID.
  var path_402656740 = newJObject()
  add(path_402656740, "Id", newJString(Id))
  result = call_402656739.call(path_402656740, nil, nil, nil, nil)

var deleteCloudFrontOriginAccessIdentity20181105* = Call_DeleteCloudFrontOriginAccessIdentity20181105_402656726(
    name: "deleteCloudFrontOriginAccessIdentity20181105",
    meth: HttpMethod.HttpDelete, host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/origin-access-identity/cloudfront/{Id}",
    validator: validate_DeleteCloudFrontOriginAccessIdentity20181105_402656727,
    base: "/", makeUrl: url_DeleteCloudFrontOriginAccessIdentity20181105_402656728,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistribution20181105_402656741 = ref object of OpenApiRestCall_402656044
proc url_GetDistribution20181105_402656743(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/distribution/"),
                 (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDistribution20181105_402656742(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get the information about a distribution. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656744 = path.getOrDefault("Id")
  valid_402656744 = validateParameter(valid_402656744, JString, required = true,
                                      default = nil)
  if valid_402656744 != nil:
    section.add "Id", valid_402656744
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656745 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656745 = validateParameter(valid_402656745, JString,
                                      required = false, default = nil)
  if valid_402656745 != nil:
    section.add "X-Amz-Security-Token", valid_402656745
  var valid_402656746 = header.getOrDefault("X-Amz-Signature")
  valid_402656746 = validateParameter(valid_402656746, JString,
                                      required = false, default = nil)
  if valid_402656746 != nil:
    section.add "X-Amz-Signature", valid_402656746
  var valid_402656747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656747 = validateParameter(valid_402656747, JString,
                                      required = false, default = nil)
  if valid_402656747 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Algorithm", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Date")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Date", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Credential")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Credential", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656752: Call_GetDistribution20181105_402656741;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the information about a distribution. 
                                                                                         ## 
  let valid = call_402656752.validator(path, query, header, formData, body, _)
  let scheme = call_402656752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656752.makeUrl(scheme.get, call_402656752.host, call_402656752.base,
                                   call_402656752.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656752, uri, valid, _)

proc call*(call_402656753: Call_GetDistribution20181105_402656741; Id: string): Recallable =
  ## getDistribution20181105
  ## Get the information about a distribution. 
  ##   Id: string (required)
                                               ##     : The distribution's ID.
  var path_402656754 = newJObject()
  add(path_402656754, "Id", newJString(Id))
  result = call_402656753.call(path_402656754, nil, nil, nil, nil)

var getDistribution20181105* = Call_GetDistribution20181105_402656741(
    name: "getDistribution20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/distribution/{Id}",
    validator: validate_GetDistribution20181105_402656742, base: "/",
    makeUrl: url_GetDistribution20181105_402656743,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDistribution20181105_402656755 = ref object of OpenApiRestCall_402656044
proc url_DeleteDistribution20181105_402656757(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/distribution/"),
                 (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDistribution20181105_402656756(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Delete a distribution. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The distribution ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656758 = path.getOrDefault("Id")
  valid_402656758 = validateParameter(valid_402656758, JString, required = true,
                                      default = nil)
  if valid_402656758 != nil:
    section.add "Id", valid_402656758
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   If-Match: JString
                               ##           : The value of the <code>ETag</code> header that you received when you disabled the distribution. For example: <code>E2QWRUHAPOMQZL</code>. 
  ##   
                                                                                                                                                                                        ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                        ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                   ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                         ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                     ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656759 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656759 = validateParameter(valid_402656759, JString,
                                      required = false, default = nil)
  if valid_402656759 != nil:
    section.add "X-Amz-Security-Token", valid_402656759
  var valid_402656760 = header.getOrDefault("X-Amz-Signature")
  valid_402656760 = validateParameter(valid_402656760, JString,
                                      required = false, default = nil)
  if valid_402656760 != nil:
    section.add "X-Amz-Signature", valid_402656760
  var valid_402656761 = header.getOrDefault("If-Match")
  valid_402656761 = validateParameter(valid_402656761, JString,
                                      required = false, default = nil)
  if valid_402656761 != nil:
    section.add "If-Match", valid_402656761
  var valid_402656762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656762 = validateParameter(valid_402656762, JString,
                                      required = false, default = nil)
  if valid_402656762 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Algorithm", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Date")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Date", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Credential")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Credential", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656767: Call_DeleteDistribution20181105_402656755;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a distribution. 
                                                                                         ## 
  let valid = call_402656767.validator(path, query, header, formData, body, _)
  let scheme = call_402656767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656767.makeUrl(scheme.get, call_402656767.host, call_402656767.base,
                                   call_402656767.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656767, uri, valid, _)

proc call*(call_402656768: Call_DeleteDistribution20181105_402656755; Id: string): Recallable =
  ## deleteDistribution20181105
  ## Delete a distribution. 
  ##   Id: string (required)
                            ##     : The distribution ID. 
  var path_402656769 = newJObject()
  add(path_402656769, "Id", newJString(Id))
  result = call_402656768.call(path_402656769, nil, nil, nil, nil)

var deleteDistribution20181105* = Call_DeleteDistribution20181105_402656755(
    name: "deleteDistribution20181105", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/distribution/{Id}",
    validator: validate_DeleteDistribution20181105_402656756, base: "/",
    makeUrl: url_DeleteDistribution20181105_402656757,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryption20181105_402656770 = ref object of OpenApiRestCall_402656044
proc url_GetFieldLevelEncryption20181105_402656772(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2018-11-05/field-level-encryption/"),
                 (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFieldLevelEncryption20181105_402656771(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Get the field-level encryption configuration information.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : Request the ID for the field-level encryption configuration information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656773 = path.getOrDefault("Id")
  valid_402656773 = validateParameter(valid_402656773, JString, required = true,
                                      default = nil)
  if valid_402656773 != nil:
    section.add "Id", valid_402656773
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656774 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656774 = validateParameter(valid_402656774, JString,
                                      required = false, default = nil)
  if valid_402656774 != nil:
    section.add "X-Amz-Security-Token", valid_402656774
  var valid_402656775 = header.getOrDefault("X-Amz-Signature")
  valid_402656775 = validateParameter(valid_402656775, JString,
                                      required = false, default = nil)
  if valid_402656775 != nil:
    section.add "X-Amz-Signature", valid_402656775
  var valid_402656776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656776 = validateParameter(valid_402656776, JString,
                                      required = false, default = nil)
  if valid_402656776 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656776
  var valid_402656777 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656777 = validateParameter(valid_402656777, JString,
                                      required = false, default = nil)
  if valid_402656777 != nil:
    section.add "X-Amz-Algorithm", valid_402656777
  var valid_402656778 = header.getOrDefault("X-Amz-Date")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-Date", valid_402656778
  var valid_402656779 = header.getOrDefault("X-Amz-Credential")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Credential", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656781: Call_GetFieldLevelEncryption20181105_402656770;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the field-level encryption configuration information.
                                                                                         ## 
  let valid = call_402656781.validator(path, query, header, formData, body, _)
  let scheme = call_402656781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656781.makeUrl(scheme.get, call_402656781.host, call_402656781.base,
                                   call_402656781.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656781, uri, valid, _)

proc call*(call_402656782: Call_GetFieldLevelEncryption20181105_402656770;
           Id: string): Recallable =
  ## getFieldLevelEncryption20181105
  ## Get the field-level encryption configuration information.
  ##   Id: string (required)
                                                              ##     : Request the ID for the field-level encryption configuration information.
  var path_402656783 = newJObject()
  add(path_402656783, "Id", newJString(Id))
  result = call_402656782.call(path_402656783, nil, nil, nil, nil)

var getFieldLevelEncryption20181105* = Call_GetFieldLevelEncryption20181105_402656770(
    name: "getFieldLevelEncryption20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption/{Id}",
    validator: validate_GetFieldLevelEncryption20181105_402656771, base: "/",
    makeUrl: url_GetFieldLevelEncryption20181105_402656772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFieldLevelEncryptionConfig20181105_402656784 = ref object of OpenApiRestCall_402656044
proc url_DeleteFieldLevelEncryptionConfig20181105_402656786(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2018-11-05/field-level-encryption/"),
                 (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFieldLevelEncryptionConfig20181105_402656785(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Remove a field-level encryption configuration.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The ID of the configuration you want to delete from CloudFront.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656787 = path.getOrDefault("Id")
  valid_402656787 = validateParameter(valid_402656787, JString, required = true,
                                      default = nil)
  if valid_402656787 != nil:
    section.add "Id", valid_402656787
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   If-Match: JString
                               ##           : The value of the <code>ETag</code> header that you received when retrieving the configuration identity to delete. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   
                                                                                                                                                                                                         ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                          ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                      ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656788 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656788 = validateParameter(valid_402656788, JString,
                                      required = false, default = nil)
  if valid_402656788 != nil:
    section.add "X-Amz-Security-Token", valid_402656788
  var valid_402656789 = header.getOrDefault("X-Amz-Signature")
  valid_402656789 = validateParameter(valid_402656789, JString,
                                      required = false, default = nil)
  if valid_402656789 != nil:
    section.add "X-Amz-Signature", valid_402656789
  var valid_402656790 = header.getOrDefault("If-Match")
  valid_402656790 = validateParameter(valid_402656790, JString,
                                      required = false, default = nil)
  if valid_402656790 != nil:
    section.add "If-Match", valid_402656790
  var valid_402656791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656791 = validateParameter(valid_402656791, JString,
                                      required = false, default = nil)
  if valid_402656791 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656791
  var valid_402656792 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656792 = validateParameter(valid_402656792, JString,
                                      required = false, default = nil)
  if valid_402656792 != nil:
    section.add "X-Amz-Algorithm", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Date")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Date", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Credential")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Credential", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656795
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656796: Call_DeleteFieldLevelEncryptionConfig20181105_402656784;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove a field-level encryption configuration.
                                                                                         ## 
  let valid = call_402656796.validator(path, query, header, formData, body, _)
  let scheme = call_402656796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656796.makeUrl(scheme.get, call_402656796.host, call_402656796.base,
                                   call_402656796.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656796, uri, valid, _)

proc call*(call_402656797: Call_DeleteFieldLevelEncryptionConfig20181105_402656784;
           Id: string): Recallable =
  ## deleteFieldLevelEncryptionConfig20181105
  ## Remove a field-level encryption configuration.
  ##   Id: string (required)
                                                   ##     : The ID of the configuration you want to delete from CloudFront.
  var path_402656798 = newJObject()
  add(path_402656798, "Id", newJString(Id))
  result = call_402656797.call(path_402656798, nil, nil, nil, nil)

var deleteFieldLevelEncryptionConfig20181105* = Call_DeleteFieldLevelEncryptionConfig20181105_402656784(
    name: "deleteFieldLevelEncryptionConfig20181105",
    meth: HttpMethod.HttpDelete, host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption/{Id}",
    validator: validate_DeleteFieldLevelEncryptionConfig20181105_402656785,
    base: "/", makeUrl: url_DeleteFieldLevelEncryptionConfig20181105_402656786,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryptionProfile20181105_402656799 = ref object of OpenApiRestCall_402656044
proc url_GetFieldLevelEncryptionProfile20181105_402656801(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2018-11-05/field-level-encryption-profile/"),
                 (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFieldLevelEncryptionProfile20181105_402656800(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Get the field-level encryption profile information.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : Get the ID for the field-level encryption profile information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656802 = path.getOrDefault("Id")
  valid_402656802 = validateParameter(valid_402656802, JString, required = true,
                                      default = nil)
  if valid_402656802 != nil:
    section.add "Id", valid_402656802
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656803 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656803 = validateParameter(valid_402656803, JString,
                                      required = false, default = nil)
  if valid_402656803 != nil:
    section.add "X-Amz-Security-Token", valid_402656803
  var valid_402656804 = header.getOrDefault("X-Amz-Signature")
  valid_402656804 = validateParameter(valid_402656804, JString,
                                      required = false, default = nil)
  if valid_402656804 != nil:
    section.add "X-Amz-Signature", valid_402656804
  var valid_402656805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656805 = validateParameter(valid_402656805, JString,
                                      required = false, default = nil)
  if valid_402656805 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656805
  var valid_402656806 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656806 = validateParameter(valid_402656806, JString,
                                      required = false, default = nil)
  if valid_402656806 != nil:
    section.add "X-Amz-Algorithm", valid_402656806
  var valid_402656807 = header.getOrDefault("X-Amz-Date")
  valid_402656807 = validateParameter(valid_402656807, JString,
                                      required = false, default = nil)
  if valid_402656807 != nil:
    section.add "X-Amz-Date", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-Credential")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Credential", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656809
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656810: Call_GetFieldLevelEncryptionProfile20181105_402656799;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the field-level encryption profile information.
                                                                                         ## 
  let valid = call_402656810.validator(path, query, header, formData, body, _)
  let scheme = call_402656810.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656810.makeUrl(scheme.get, call_402656810.host, call_402656810.base,
                                   call_402656810.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656810, uri, valid, _)

proc call*(call_402656811: Call_GetFieldLevelEncryptionProfile20181105_402656799;
           Id: string): Recallable =
  ## getFieldLevelEncryptionProfile20181105
  ## Get the field-level encryption profile information.
  ##   Id: string (required)
                                                        ##     : Get the ID for the field-level encryption profile information.
  var path_402656812 = newJObject()
  add(path_402656812, "Id", newJString(Id))
  result = call_402656811.call(path_402656812, nil, nil, nil, nil)

var getFieldLevelEncryptionProfile20181105* = Call_GetFieldLevelEncryptionProfile20181105_402656799(
    name: "getFieldLevelEncryptionProfile20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption-profile/{Id}",
    validator: validate_GetFieldLevelEncryptionProfile20181105_402656800,
    base: "/", makeUrl: url_GetFieldLevelEncryptionProfile20181105_402656801,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFieldLevelEncryptionProfile20181105_402656813 = ref object of OpenApiRestCall_402656044
proc url_DeleteFieldLevelEncryptionProfile20181105_402656815(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2018-11-05/field-level-encryption-profile/"),
                 (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFieldLevelEncryptionProfile20181105_402656814(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Remove a field-level encryption profile.
                                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : Request the ID of the profile you want to delete from CloudFront.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656816 = path.getOrDefault("Id")
  valid_402656816 = validateParameter(valid_402656816, JString, required = true,
                                      default = nil)
  if valid_402656816 != nil:
    section.add "Id", valid_402656816
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   If-Match: JString
                               ##           : The value of the <code>ETag</code> header that you received when retrieving the profile to delete. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   
                                                                                                                                                                                          ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                          ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                     ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                           ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                       ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656817 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656817 = validateParameter(valid_402656817, JString,
                                      required = false, default = nil)
  if valid_402656817 != nil:
    section.add "X-Amz-Security-Token", valid_402656817
  var valid_402656818 = header.getOrDefault("X-Amz-Signature")
  valid_402656818 = validateParameter(valid_402656818, JString,
                                      required = false, default = nil)
  if valid_402656818 != nil:
    section.add "X-Amz-Signature", valid_402656818
  var valid_402656819 = header.getOrDefault("If-Match")
  valid_402656819 = validateParameter(valid_402656819, JString,
                                      required = false, default = nil)
  if valid_402656819 != nil:
    section.add "If-Match", valid_402656819
  var valid_402656820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656820 = validateParameter(valid_402656820, JString,
                                      required = false, default = nil)
  if valid_402656820 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656820
  var valid_402656821 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656821 = validateParameter(valid_402656821, JString,
                                      required = false, default = nil)
  if valid_402656821 != nil:
    section.add "X-Amz-Algorithm", valid_402656821
  var valid_402656822 = header.getOrDefault("X-Amz-Date")
  valid_402656822 = validateParameter(valid_402656822, JString,
                                      required = false, default = nil)
  if valid_402656822 != nil:
    section.add "X-Amz-Date", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Credential")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Credential", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656825: Call_DeleteFieldLevelEncryptionProfile20181105_402656813;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove a field-level encryption profile.
                                                                                         ## 
  let valid = call_402656825.validator(path, query, header, formData, body, _)
  let scheme = call_402656825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656825.makeUrl(scheme.get, call_402656825.host, call_402656825.base,
                                   call_402656825.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656825, uri, valid, _)

proc call*(call_402656826: Call_DeleteFieldLevelEncryptionProfile20181105_402656813;
           Id: string): Recallable =
  ## deleteFieldLevelEncryptionProfile20181105
  ## Remove a field-level encryption profile.
  ##   Id: string (required)
                                             ##     : Request the ID of the profile you want to delete from CloudFront.
  var path_402656827 = newJObject()
  add(path_402656827, "Id", newJString(Id))
  result = call_402656826.call(path_402656827, nil, nil, nil, nil)

var deleteFieldLevelEncryptionProfile20181105* = Call_DeleteFieldLevelEncryptionProfile20181105_402656813(
    name: "deleteFieldLevelEncryptionProfile20181105",
    meth: HttpMethod.HttpDelete, host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption-profile/{Id}",
    validator: validate_DeleteFieldLevelEncryptionProfile20181105_402656814,
    base: "/", makeUrl: url_DeleteFieldLevelEncryptionProfile20181105_402656815,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicKey20181105_402656828 = ref object of OpenApiRestCall_402656044
proc url_GetPublicKey20181105_402656830(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/public-key/"),
                 (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPublicKey20181105_402656829(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get the public key information.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : Request the ID for the public key.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656831 = path.getOrDefault("Id")
  valid_402656831 = validateParameter(valid_402656831, JString, required = true,
                                      default = nil)
  if valid_402656831 != nil:
    section.add "Id", valid_402656831
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656832 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656832 = validateParameter(valid_402656832, JString,
                                      required = false, default = nil)
  if valid_402656832 != nil:
    section.add "X-Amz-Security-Token", valid_402656832
  var valid_402656833 = header.getOrDefault("X-Amz-Signature")
  valid_402656833 = validateParameter(valid_402656833, JString,
                                      required = false, default = nil)
  if valid_402656833 != nil:
    section.add "X-Amz-Signature", valid_402656833
  var valid_402656834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656834 = validateParameter(valid_402656834, JString,
                                      required = false, default = nil)
  if valid_402656834 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656834
  var valid_402656835 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656835 = validateParameter(valid_402656835, JString,
                                      required = false, default = nil)
  if valid_402656835 != nil:
    section.add "X-Amz-Algorithm", valid_402656835
  var valid_402656836 = header.getOrDefault("X-Amz-Date")
  valid_402656836 = validateParameter(valid_402656836, JString,
                                      required = false, default = nil)
  if valid_402656836 != nil:
    section.add "X-Amz-Date", valid_402656836
  var valid_402656837 = header.getOrDefault("X-Amz-Credential")
  valid_402656837 = validateParameter(valid_402656837, JString,
                                      required = false, default = nil)
  if valid_402656837 != nil:
    section.add "X-Amz-Credential", valid_402656837
  var valid_402656838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656839: Call_GetPublicKey20181105_402656828;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the public key information.
                                                                                         ## 
  let valid = call_402656839.validator(path, query, header, formData, body, _)
  let scheme = call_402656839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656839.makeUrl(scheme.get, call_402656839.host, call_402656839.base,
                                   call_402656839.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656839, uri, valid, _)

proc call*(call_402656840: Call_GetPublicKey20181105_402656828; Id: string): Recallable =
  ## getPublicKey20181105
  ## Get the public key information.
  ##   Id: string (required)
                                    ##     : Request the ID for the public key.
  var path_402656841 = newJObject()
  add(path_402656841, "Id", newJString(Id))
  result = call_402656840.call(path_402656841, nil, nil, nil, nil)

var getPublicKey20181105* = Call_GetPublicKey20181105_402656828(
    name: "getPublicKey20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/public-key/{Id}",
    validator: validate_GetPublicKey20181105_402656829, base: "/",
    makeUrl: url_GetPublicKey20181105_402656830,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicKey20181105_402656842 = ref object of OpenApiRestCall_402656044
proc url_DeletePublicKey20181105_402656844(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/public-key/"),
                 (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeletePublicKey20181105_402656843(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Remove a public key you previously added to CloudFront.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The ID of the public key you want to remove from CloudFront.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656845 = path.getOrDefault("Id")
  valid_402656845 = validateParameter(valid_402656845, JString, required = true,
                                      default = nil)
  if valid_402656845 != nil:
    section.add "Id", valid_402656845
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   If-Match: JString
                               ##           : The value of the <code>ETag</code> header that you received when retrieving the public key identity to delete. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   
                                                                                                                                                                                                      ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                      ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                 ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                       ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                   ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656846 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656846 = validateParameter(valid_402656846, JString,
                                      required = false, default = nil)
  if valid_402656846 != nil:
    section.add "X-Amz-Security-Token", valid_402656846
  var valid_402656847 = header.getOrDefault("X-Amz-Signature")
  valid_402656847 = validateParameter(valid_402656847, JString,
                                      required = false, default = nil)
  if valid_402656847 != nil:
    section.add "X-Amz-Signature", valid_402656847
  var valid_402656848 = header.getOrDefault("If-Match")
  valid_402656848 = validateParameter(valid_402656848, JString,
                                      required = false, default = nil)
  if valid_402656848 != nil:
    section.add "If-Match", valid_402656848
  var valid_402656849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656849 = validateParameter(valid_402656849, JString,
                                      required = false, default = nil)
  if valid_402656849 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656849
  var valid_402656850 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656850 = validateParameter(valid_402656850, JString,
                                      required = false, default = nil)
  if valid_402656850 != nil:
    section.add "X-Amz-Algorithm", valid_402656850
  var valid_402656851 = header.getOrDefault("X-Amz-Date")
  valid_402656851 = validateParameter(valid_402656851, JString,
                                      required = false, default = nil)
  if valid_402656851 != nil:
    section.add "X-Amz-Date", valid_402656851
  var valid_402656852 = header.getOrDefault("X-Amz-Credential")
  valid_402656852 = validateParameter(valid_402656852, JString,
                                      required = false, default = nil)
  if valid_402656852 != nil:
    section.add "X-Amz-Credential", valid_402656852
  var valid_402656853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656853 = validateParameter(valid_402656853, JString,
                                      required = false, default = nil)
  if valid_402656853 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656854: Call_DeletePublicKey20181105_402656842;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove a public key you previously added to CloudFront.
                                                                                         ## 
  let valid = call_402656854.validator(path, query, header, formData, body, _)
  let scheme = call_402656854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656854.makeUrl(scheme.get, call_402656854.host, call_402656854.base,
                                   call_402656854.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656854, uri, valid, _)

proc call*(call_402656855: Call_DeletePublicKey20181105_402656842; Id: string): Recallable =
  ## deletePublicKey20181105
  ## Remove a public key you previously added to CloudFront.
  ##   Id: string (required)
                                                            ##     : The ID of the public key you want to remove from CloudFront.
  var path_402656856 = newJObject()
  add(path_402656856, "Id", newJString(Id))
  result = call_402656855.call(path_402656856, nil, nil, nil, nil)

var deletePublicKey20181105* = Call_DeletePublicKey20181105_402656842(
    name: "deletePublicKey20181105", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/public-key/{Id}",
    validator: validate_DeletePublicKey20181105_402656843, base: "/",
    makeUrl: url_DeletePublicKey20181105_402656844,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistribution20181105_402656857 = ref object of OpenApiRestCall_402656044
proc url_GetStreamingDistribution20181105_402656859(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2018-11-05/streaming-distribution/"),
                 (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStreamingDistribution20181105_402656858(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The streaming distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656860 = path.getOrDefault("Id")
  valid_402656860 = validateParameter(valid_402656860, JString, required = true,
                                      default = nil)
  if valid_402656860 != nil:
    section.add "Id", valid_402656860
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656861 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "X-Amz-Security-Token", valid_402656861
  var valid_402656862 = header.getOrDefault("X-Amz-Signature")
  valid_402656862 = validateParameter(valid_402656862, JString,
                                      required = false, default = nil)
  if valid_402656862 != nil:
    section.add "X-Amz-Signature", valid_402656862
  var valid_402656863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656863 = validateParameter(valid_402656863, JString,
                                      required = false, default = nil)
  if valid_402656863 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656863
  var valid_402656864 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656864 = validateParameter(valid_402656864, JString,
                                      required = false, default = nil)
  if valid_402656864 != nil:
    section.add "X-Amz-Algorithm", valid_402656864
  var valid_402656865 = header.getOrDefault("X-Amz-Date")
  valid_402656865 = validateParameter(valid_402656865, JString,
                                      required = false, default = nil)
  if valid_402656865 != nil:
    section.add "X-Amz-Date", valid_402656865
  var valid_402656866 = header.getOrDefault("X-Amz-Credential")
  valid_402656866 = validateParameter(valid_402656866, JString,
                                      required = false, default = nil)
  if valid_402656866 != nil:
    section.add "X-Amz-Credential", valid_402656866
  var valid_402656867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656867 = validateParameter(valid_402656867, JString,
                                      required = false, default = nil)
  if valid_402656867 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656867
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656868: Call_GetStreamingDistribution20181105_402656857;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
                                                                                         ## 
  let valid = call_402656868.validator(path, query, header, formData, body, _)
  let scheme = call_402656868.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656868.makeUrl(scheme.get, call_402656868.host, call_402656868.base,
                                   call_402656868.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656868, uri, valid, _)

proc call*(call_402656869: Call_GetStreamingDistribution20181105_402656857;
           Id: string): Recallable =
  ## getStreamingDistribution20181105
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ##   
                                                                                                    ## Id: string (required)
                                                                                                    ##     
                                                                                                    ## : 
                                                                                                    ## The 
                                                                                                    ## streaming 
                                                                                                    ## distribution's 
                                                                                                    ## ID.
  var path_402656870 = newJObject()
  add(path_402656870, "Id", newJString(Id))
  result = call_402656869.call(path_402656870, nil, nil, nil, nil)

var getStreamingDistribution20181105* = Call_GetStreamingDistribution20181105_402656857(
    name: "getStreamingDistribution20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/streaming-distribution/{Id}",
    validator: validate_GetStreamingDistribution20181105_402656858, base: "/",
    makeUrl: url_GetStreamingDistribution20181105_402656859,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStreamingDistribution20181105_402656871 = ref object of OpenApiRestCall_402656044
proc url_DeleteStreamingDistribution20181105_402656873(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2018-11-05/streaming-distribution/"),
                 (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteStreamingDistribution20181105_402656872(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The distribution ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656874 = path.getOrDefault("Id")
  valid_402656874 = validateParameter(valid_402656874, JString, required = true,
                                      default = nil)
  if valid_402656874 != nil:
    section.add "Id", valid_402656874
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   If-Match: JString
                               ##           : The value of the <code>ETag</code> header that you received when you disabled the streaming distribution. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   
                                                                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656875 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656875 = validateParameter(valid_402656875, JString,
                                      required = false, default = nil)
  if valid_402656875 != nil:
    section.add "X-Amz-Security-Token", valid_402656875
  var valid_402656876 = header.getOrDefault("X-Amz-Signature")
  valid_402656876 = validateParameter(valid_402656876, JString,
                                      required = false, default = nil)
  if valid_402656876 != nil:
    section.add "X-Amz-Signature", valid_402656876
  var valid_402656877 = header.getOrDefault("If-Match")
  valid_402656877 = validateParameter(valid_402656877, JString,
                                      required = false, default = nil)
  if valid_402656877 != nil:
    section.add "If-Match", valid_402656877
  var valid_402656878 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656878 = validateParameter(valid_402656878, JString,
                                      required = false, default = nil)
  if valid_402656878 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656878
  var valid_402656879 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656879 = validateParameter(valid_402656879, JString,
                                      required = false, default = nil)
  if valid_402656879 != nil:
    section.add "X-Amz-Algorithm", valid_402656879
  var valid_402656880 = header.getOrDefault("X-Amz-Date")
  valid_402656880 = validateParameter(valid_402656880, JString,
                                      required = false, default = nil)
  if valid_402656880 != nil:
    section.add "X-Amz-Date", valid_402656880
  var valid_402656881 = header.getOrDefault("X-Amz-Credential")
  valid_402656881 = validateParameter(valid_402656881, JString,
                                      required = false, default = nil)
  if valid_402656881 != nil:
    section.add "X-Amz-Credential", valid_402656881
  var valid_402656882 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656882 = validateParameter(valid_402656882, JString,
                                      required = false, default = nil)
  if valid_402656882 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656882
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656883: Call_DeleteStreamingDistribution20181105_402656871;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656883.validator(path, query, header, formData, body, _)
  let scheme = call_402656883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656883.makeUrl(scheme.get, call_402656883.host, call_402656883.base,
                                   call_402656883.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656883, uri, valid, _)

proc call*(call_402656884: Call_DeleteStreamingDistribution20181105_402656871;
           Id: string): Recallable =
  ## deleteStreamingDistribution20181105
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## Id: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ##     
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## distribution 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## ID. 
  var path_402656885 = newJObject()
  add(path_402656885, "Id", newJString(Id))
  result = call_402656884.call(path_402656885, nil, nil, nil, nil)

var deleteStreamingDistribution20181105* = Call_DeleteStreamingDistribution20181105_402656871(
    name: "deleteStreamingDistribution20181105", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/streaming-distribution/{Id}",
    validator: validate_DeleteStreamingDistribution20181105_402656872,
    base: "/", makeUrl: url_DeleteStreamingDistribution20181105_402656873,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCloudFrontOriginAccessIdentity20181105_402656900 = ref object of OpenApiRestCall_402656044
proc url_UpdateCloudFrontOriginAccessIdentity20181105_402656902(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2018-11-05/origin-access-identity/cloudfront/"),
                 (kind: VariableSegment, value: "Id"),
                 (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateCloudFrontOriginAccessIdentity20181105_402656901(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Update an origin access identity. 
                                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The identity's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656903 = path.getOrDefault("Id")
  valid_402656903 = validateParameter(valid_402656903, JString, required = true,
                                      default = nil)
  if valid_402656903 != nil:
    section.add "Id", valid_402656903
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   If-Match: JString
                               ##           : The value of the <code>ETag</code> header that you received when retrieving the identity's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   
                                                                                                                                                                                                 ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                 ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                            ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                  ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                              ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656904 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "X-Amz-Security-Token", valid_402656904
  var valid_402656905 = header.getOrDefault("X-Amz-Signature")
  valid_402656905 = validateParameter(valid_402656905, JString,
                                      required = false, default = nil)
  if valid_402656905 != nil:
    section.add "X-Amz-Signature", valid_402656905
  var valid_402656906 = header.getOrDefault("If-Match")
  valid_402656906 = validateParameter(valid_402656906, JString,
                                      required = false, default = nil)
  if valid_402656906 != nil:
    section.add "If-Match", valid_402656906
  var valid_402656907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656907 = validateParameter(valid_402656907, JString,
                                      required = false, default = nil)
  if valid_402656907 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656907
  var valid_402656908 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656908 = validateParameter(valid_402656908, JString,
                                      required = false, default = nil)
  if valid_402656908 != nil:
    section.add "X-Amz-Algorithm", valid_402656908
  var valid_402656909 = header.getOrDefault("X-Amz-Date")
  valid_402656909 = validateParameter(valid_402656909, JString,
                                      required = false, default = nil)
  if valid_402656909 != nil:
    section.add "X-Amz-Date", valid_402656909
  var valid_402656910 = header.getOrDefault("X-Amz-Credential")
  valid_402656910 = validateParameter(valid_402656910, JString,
                                      required = false, default = nil)
  if valid_402656910 != nil:
    section.add "X-Amz-Credential", valid_402656910
  var valid_402656911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656911 = validateParameter(valid_402656911, JString,
                                      required = false, default = nil)
  if valid_402656911 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656913: Call_UpdateCloudFrontOriginAccessIdentity20181105_402656900;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update an origin access identity. 
                                                                                         ## 
  let valid = call_402656913.validator(path, query, header, formData, body, _)
  let scheme = call_402656913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656913.makeUrl(scheme.get, call_402656913.host, call_402656913.base,
                                   call_402656913.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656913, uri, valid, _)

proc call*(call_402656914: Call_UpdateCloudFrontOriginAccessIdentity20181105_402656900;
           body: JsonNode; Id: string): Recallable =
  ## updateCloudFrontOriginAccessIdentity20181105
  ## Update an origin access identity. 
  ##   body: JObject (required)
  ##   Id: string (required)
                               ##     : The identity's id.
  var path_402656915 = newJObject()
  var body_402656916 = newJObject()
  if body != nil:
    body_402656916 = body
  add(path_402656915, "Id", newJString(Id))
  result = call_402656914.call(path_402656915, nil, nil, nil, body_402656916)

var updateCloudFrontOriginAccessIdentity20181105* = Call_UpdateCloudFrontOriginAccessIdentity20181105_402656900(
    name: "updateCloudFrontOriginAccessIdentity20181105",
    meth: HttpMethod.HttpPut, host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_UpdateCloudFrontOriginAccessIdentity20181105_402656901,
    base: "/", makeUrl: url_UpdateCloudFrontOriginAccessIdentity20181105_402656902,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentityConfig20181105_402656886 = ref object of OpenApiRestCall_402656044
proc url_GetCloudFrontOriginAccessIdentityConfig20181105_402656888(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2018-11-05/origin-access-identity/cloudfront/"),
                 (kind: VariableSegment, value: "Id"),
                 (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCloudFrontOriginAccessIdentityConfig20181105_402656887(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Get the configuration information about an origin access identity. 
                                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The identity's ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656889 = path.getOrDefault("Id")
  valid_402656889 = validateParameter(valid_402656889, JString, required = true,
                                      default = nil)
  if valid_402656889 != nil:
    section.add "Id", valid_402656889
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656890 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "X-Amz-Security-Token", valid_402656890
  var valid_402656891 = header.getOrDefault("X-Amz-Signature")
  valid_402656891 = validateParameter(valid_402656891, JString,
                                      required = false, default = nil)
  if valid_402656891 != nil:
    section.add "X-Amz-Signature", valid_402656891
  var valid_402656892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656892 = validateParameter(valid_402656892, JString,
                                      required = false, default = nil)
  if valid_402656892 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656892
  var valid_402656893 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656893 = validateParameter(valid_402656893, JString,
                                      required = false, default = nil)
  if valid_402656893 != nil:
    section.add "X-Amz-Algorithm", valid_402656893
  var valid_402656894 = header.getOrDefault("X-Amz-Date")
  valid_402656894 = validateParameter(valid_402656894, JString,
                                      required = false, default = nil)
  if valid_402656894 != nil:
    section.add "X-Amz-Date", valid_402656894
  var valid_402656895 = header.getOrDefault("X-Amz-Credential")
  valid_402656895 = validateParameter(valid_402656895, JString,
                                      required = false, default = nil)
  if valid_402656895 != nil:
    section.add "X-Amz-Credential", valid_402656895
  var valid_402656896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656896 = validateParameter(valid_402656896, JString,
                                      required = false, default = nil)
  if valid_402656896 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656897: Call_GetCloudFrontOriginAccessIdentityConfig20181105_402656886;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the configuration information about an origin access identity. 
                                                                                         ## 
  let valid = call_402656897.validator(path, query, header, formData, body, _)
  let scheme = call_402656897.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656897.makeUrl(scheme.get, call_402656897.host, call_402656897.base,
                                   call_402656897.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656897, uri, valid, _)

proc call*(call_402656898: Call_GetCloudFrontOriginAccessIdentityConfig20181105_402656886;
           Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentityConfig20181105
  ## Get the configuration information about an origin access identity. 
  ##   Id: string 
                                                                        ## (required)
                                                                        ##     
                                                                        ## : 
                                                                        ## The 
                                                                        ## identity's 
                                                                        ## ID. 
  var path_402656899 = newJObject()
  add(path_402656899, "Id", newJString(Id))
  result = call_402656898.call(path_402656899, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentityConfig20181105* = Call_GetCloudFrontOriginAccessIdentityConfig20181105_402656886(
    name: "getCloudFrontOriginAccessIdentityConfig20181105",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_GetCloudFrontOriginAccessIdentityConfig20181105_402656887,
    base: "/", makeUrl: url_GetCloudFrontOriginAccessIdentityConfig20181105_402656888,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDistribution20181105_402656931 = ref object of OpenApiRestCall_402656044
proc url_UpdateDistribution20181105_402656933(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/distribution/"),
                 (kind: VariableSegment, value: "Id"),
                 (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDistribution20181105_402656932(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Updates the configuration for a web distribution. </p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using this API action, follow the steps here to get the current configuration and then make your updates, to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>The update process includes getting the current distribution configuration, updating the XML document that is returned to make your changes, and then submitting an <code>UpdateDistribution</code> request to make the updates.</p> <p>For information about updating a distribution using the CloudFront console instead, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a>GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you must get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include your changes. </p> <important> <p>When you edit the XML file, be aware of the following:</p> <ul> <li> <p>You must strip out the ETag parameter that is returned.</p> </li> <li> <p>Additional fields are required when you update a distribution. There may be fields included in the XML file for features that you haven't configured for your distribution. This is expected and required to successfully update the distribution.</p> </li> <li> <p>You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error. </p> </li> <li> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into your existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </li> </ul> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a>GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> </ol>
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656934 = path.getOrDefault("Id")
  valid_402656934 = validateParameter(valid_402656934, JString, required = true,
                                      default = nil)
  if valid_402656934 != nil:
    section.add "Id", valid_402656934
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   If-Match: JString
                               ##           : The value of the <code>ETag</code> header that you received when retrieving the distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   
                                                                                                                                                                                                     ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                     ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                      ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                  ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656935 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656935 = validateParameter(valid_402656935, JString,
                                      required = false, default = nil)
  if valid_402656935 != nil:
    section.add "X-Amz-Security-Token", valid_402656935
  var valid_402656936 = header.getOrDefault("X-Amz-Signature")
  valid_402656936 = validateParameter(valid_402656936, JString,
                                      required = false, default = nil)
  if valid_402656936 != nil:
    section.add "X-Amz-Signature", valid_402656936
  var valid_402656937 = header.getOrDefault("If-Match")
  valid_402656937 = validateParameter(valid_402656937, JString,
                                      required = false, default = nil)
  if valid_402656937 != nil:
    section.add "If-Match", valid_402656937
  var valid_402656938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656938 = validateParameter(valid_402656938, JString,
                                      required = false, default = nil)
  if valid_402656938 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656938
  var valid_402656939 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656939 = validateParameter(valid_402656939, JString,
                                      required = false, default = nil)
  if valid_402656939 != nil:
    section.add "X-Amz-Algorithm", valid_402656939
  var valid_402656940 = header.getOrDefault("X-Amz-Date")
  valid_402656940 = validateParameter(valid_402656940, JString,
                                      required = false, default = nil)
  if valid_402656940 != nil:
    section.add "X-Amz-Date", valid_402656940
  var valid_402656941 = header.getOrDefault("X-Amz-Credential")
  valid_402656941 = validateParameter(valid_402656941, JString,
                                      required = false, default = nil)
  if valid_402656941 != nil:
    section.add "X-Amz-Credential", valid_402656941
  var valid_402656942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656942 = validateParameter(valid_402656942, JString,
                                      required = false, default = nil)
  if valid_402656942 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656944: Call_UpdateDistribution20181105_402656931;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the configuration for a web distribution. </p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using this API action, follow the steps here to get the current configuration and then make your updates, to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>The update process includes getting the current distribution configuration, updating the XML document that is returned to make your changes, and then submitting an <code>UpdateDistribution</code> request to make the updates.</p> <p>For information about updating a distribution using the CloudFront console instead, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a>GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you must get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include your changes. </p> <important> <p>When you edit the XML file, be aware of the following:</p> <ul> <li> <p>You must strip out the ETag parameter that is returned.</p> </li> <li> <p>Additional fields are required when you update a distribution. There may be fields included in the XML file for features that you haven't configured for your distribution. This is expected and required to successfully update the distribution.</p> </li> <li> <p>You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error. </p> </li> <li> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into your existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </li> </ul> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a>GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> </ol>
                                                                                         ## 
  let valid = call_402656944.validator(path, query, header, formData, body, _)
  let scheme = call_402656944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656944.makeUrl(scheme.get, call_402656944.host, call_402656944.base,
                                   call_402656944.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656944, uri, valid, _)

proc call*(call_402656945: Call_UpdateDistribution20181105_402656931;
           body: JsonNode; Id: string): Recallable =
  ## updateDistribution20181105
  ## <p>Updates the configuration for a web distribution. </p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using this API action, follow the steps here to get the current configuration and then make your updates, to make sure that you include all of the required fields. To view a summary, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>The update process includes getting the current distribution configuration, updating the XML document that is returned to make your changes, and then submitting an <code>UpdateDistribution</code> request to make the updates.</p> <p>For information about updating a distribution using the CloudFront console instead, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a>GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you must get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include your changes. </p> <important> <p>When you edit the XML file, be aware of the following:</p> <ul> <li> <p>You must strip out the ETag parameter that is returned.</p> </li> <li> <p>Additional fields are required when you update a distribution. There may be fields included in the XML file for features that you haven't configured for your distribution. This is expected and required to successfully update the distribution.</p> </li> <li> <p>You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error. </p> </li> <li> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into your existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </li> </ul> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a>GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> </ol>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## Id: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ##     
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## distribution's 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## id.
  var path_402656946 = newJObject()
  var body_402656947 = newJObject()
  if body != nil:
    body_402656947 = body
  add(path_402656946, "Id", newJString(Id))
  result = call_402656945.call(path_402656946, nil, nil, nil, body_402656947)

var updateDistribution20181105* = Call_UpdateDistribution20181105_402656931(
    name: "updateDistribution20181105", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/distribution/{Id}/config",
    validator: validate_UpdateDistribution20181105_402656932, base: "/",
    makeUrl: url_UpdateDistribution20181105_402656933,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistributionConfig20181105_402656917 = ref object of OpenApiRestCall_402656044
proc url_GetDistributionConfig20181105_402656919(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/distribution/"),
                 (kind: VariableSegment, value: "Id"),
                 (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDistributionConfig20181105_402656918(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Get the configuration information about a distribution. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656920 = path.getOrDefault("Id")
  valid_402656920 = validateParameter(valid_402656920, JString, required = true,
                                      default = nil)
  if valid_402656920 != nil:
    section.add "Id", valid_402656920
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656921 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656921 = validateParameter(valid_402656921, JString,
                                      required = false, default = nil)
  if valid_402656921 != nil:
    section.add "X-Amz-Security-Token", valid_402656921
  var valid_402656922 = header.getOrDefault("X-Amz-Signature")
  valid_402656922 = validateParameter(valid_402656922, JString,
                                      required = false, default = nil)
  if valid_402656922 != nil:
    section.add "X-Amz-Signature", valid_402656922
  var valid_402656923 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656923 = validateParameter(valid_402656923, JString,
                                      required = false, default = nil)
  if valid_402656923 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656923
  var valid_402656924 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656924 = validateParameter(valid_402656924, JString,
                                      required = false, default = nil)
  if valid_402656924 != nil:
    section.add "X-Amz-Algorithm", valid_402656924
  var valid_402656925 = header.getOrDefault("X-Amz-Date")
  valid_402656925 = validateParameter(valid_402656925, JString,
                                      required = false, default = nil)
  if valid_402656925 != nil:
    section.add "X-Amz-Date", valid_402656925
  var valid_402656926 = header.getOrDefault("X-Amz-Credential")
  valid_402656926 = validateParameter(valid_402656926, JString,
                                      required = false, default = nil)
  if valid_402656926 != nil:
    section.add "X-Amz-Credential", valid_402656926
  var valid_402656927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656927 = validateParameter(valid_402656927, JString,
                                      required = false, default = nil)
  if valid_402656927 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656928: Call_GetDistributionConfig20181105_402656917;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the configuration information about a distribution. 
                                                                                         ## 
  let valid = call_402656928.validator(path, query, header, formData, body, _)
  let scheme = call_402656928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656928.makeUrl(scheme.get, call_402656928.host, call_402656928.base,
                                   call_402656928.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656928, uri, valid, _)

proc call*(call_402656929: Call_GetDistributionConfig20181105_402656917;
           Id: string): Recallable =
  ## getDistributionConfig20181105
  ## Get the configuration information about a distribution. 
  ##   Id: string (required)
                                                             ##     : The distribution's ID.
  var path_402656930 = newJObject()
  add(path_402656930, "Id", newJString(Id))
  result = call_402656929.call(path_402656930, nil, nil, nil, nil)

var getDistributionConfig20181105* = Call_GetDistributionConfig20181105_402656917(
    name: "getDistributionConfig20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/distribution/{Id}/config",
    validator: validate_GetDistributionConfig20181105_402656918, base: "/",
    makeUrl: url_GetDistributionConfig20181105_402656919,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFieldLevelEncryptionConfig20181105_402656962 = ref object of OpenApiRestCall_402656044
proc url_UpdateFieldLevelEncryptionConfig20181105_402656964(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2018-11-05/field-level-encryption/"),
                 (kind: VariableSegment, value: "Id"),
                 (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFieldLevelEncryptionConfig20181105_402656963(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Update a field-level encryption configuration. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The ID of the configuration you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656965 = path.getOrDefault("Id")
  valid_402656965 = validateParameter(valid_402656965, JString, required = true,
                                      default = nil)
  if valid_402656965 != nil:
    section.add "Id", valid_402656965
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   If-Match: JString
                               ##           : The value of the <code>ETag</code> header that you received when retrieving the configuration identity to update. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   
                                                                                                                                                                                                         ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                         ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                    ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                          ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                      ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656966 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656966 = validateParameter(valid_402656966, JString,
                                      required = false, default = nil)
  if valid_402656966 != nil:
    section.add "X-Amz-Security-Token", valid_402656966
  var valid_402656967 = header.getOrDefault("X-Amz-Signature")
  valid_402656967 = validateParameter(valid_402656967, JString,
                                      required = false, default = nil)
  if valid_402656967 != nil:
    section.add "X-Amz-Signature", valid_402656967
  var valid_402656968 = header.getOrDefault("If-Match")
  valid_402656968 = validateParameter(valid_402656968, JString,
                                      required = false, default = nil)
  if valid_402656968 != nil:
    section.add "If-Match", valid_402656968
  var valid_402656969 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656969 = validateParameter(valid_402656969, JString,
                                      required = false, default = nil)
  if valid_402656969 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656969
  var valid_402656970 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656970 = validateParameter(valid_402656970, JString,
                                      required = false, default = nil)
  if valid_402656970 != nil:
    section.add "X-Amz-Algorithm", valid_402656970
  var valid_402656971 = header.getOrDefault("X-Amz-Date")
  valid_402656971 = validateParameter(valid_402656971, JString,
                                      required = false, default = nil)
  if valid_402656971 != nil:
    section.add "X-Amz-Date", valid_402656971
  var valid_402656972 = header.getOrDefault("X-Amz-Credential")
  valid_402656972 = validateParameter(valid_402656972, JString,
                                      required = false, default = nil)
  if valid_402656972 != nil:
    section.add "X-Amz-Credential", valid_402656972
  var valid_402656973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656973 = validateParameter(valid_402656973, JString,
                                      required = false, default = nil)
  if valid_402656973 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656973
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656975: Call_UpdateFieldLevelEncryptionConfig20181105_402656962;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update a field-level encryption configuration. 
                                                                                         ## 
  let valid = call_402656975.validator(path, query, header, formData, body, _)
  let scheme = call_402656975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656975.makeUrl(scheme.get, call_402656975.host, call_402656975.base,
                                   call_402656975.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656975, uri, valid, _)

proc call*(call_402656976: Call_UpdateFieldLevelEncryptionConfig20181105_402656962;
           body: JsonNode; Id: string): Recallable =
  ## updateFieldLevelEncryptionConfig20181105
  ## Update a field-level encryption configuration. 
  ##   body: JObject (required)
  ##   Id: string (required)
                               ##     : The ID of the configuration you want to update.
  var path_402656977 = newJObject()
  var body_402656978 = newJObject()
  if body != nil:
    body_402656978 = body
  add(path_402656977, "Id", newJString(Id))
  result = call_402656976.call(path_402656977, nil, nil, nil, body_402656978)

var updateFieldLevelEncryptionConfig20181105* = Call_UpdateFieldLevelEncryptionConfig20181105_402656962(
    name: "updateFieldLevelEncryptionConfig20181105", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption/{Id}/config",
    validator: validate_UpdateFieldLevelEncryptionConfig20181105_402656963,
    base: "/", makeUrl: url_UpdateFieldLevelEncryptionConfig20181105_402656964,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryptionConfig20181105_402656948 = ref object of OpenApiRestCall_402656044
proc url_GetFieldLevelEncryptionConfig20181105_402656950(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2018-11-05/field-level-encryption/"),
                 (kind: VariableSegment, value: "Id"),
                 (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFieldLevelEncryptionConfig20181105_402656949(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Get the field-level encryption configuration information.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : Request the ID for the field-level encryption configuration information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656951 = path.getOrDefault("Id")
  valid_402656951 = validateParameter(valid_402656951, JString, required = true,
                                      default = nil)
  if valid_402656951 != nil:
    section.add "Id", valid_402656951
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656952 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656952 = validateParameter(valid_402656952, JString,
                                      required = false, default = nil)
  if valid_402656952 != nil:
    section.add "X-Amz-Security-Token", valid_402656952
  var valid_402656953 = header.getOrDefault("X-Amz-Signature")
  valid_402656953 = validateParameter(valid_402656953, JString,
                                      required = false, default = nil)
  if valid_402656953 != nil:
    section.add "X-Amz-Signature", valid_402656953
  var valid_402656954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656954 = validateParameter(valid_402656954, JString,
                                      required = false, default = nil)
  if valid_402656954 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656954
  var valid_402656955 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656955 = validateParameter(valid_402656955, JString,
                                      required = false, default = nil)
  if valid_402656955 != nil:
    section.add "X-Amz-Algorithm", valid_402656955
  var valid_402656956 = header.getOrDefault("X-Amz-Date")
  valid_402656956 = validateParameter(valid_402656956, JString,
                                      required = false, default = nil)
  if valid_402656956 != nil:
    section.add "X-Amz-Date", valid_402656956
  var valid_402656957 = header.getOrDefault("X-Amz-Credential")
  valid_402656957 = validateParameter(valid_402656957, JString,
                                      required = false, default = nil)
  if valid_402656957 != nil:
    section.add "X-Amz-Credential", valid_402656957
  var valid_402656958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656958 = validateParameter(valid_402656958, JString,
                                      required = false, default = nil)
  if valid_402656958 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656958
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656959: Call_GetFieldLevelEncryptionConfig20181105_402656948;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the field-level encryption configuration information.
                                                                                         ## 
  let valid = call_402656959.validator(path, query, header, formData, body, _)
  let scheme = call_402656959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656959.makeUrl(scheme.get, call_402656959.host, call_402656959.base,
                                   call_402656959.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656959, uri, valid, _)

proc call*(call_402656960: Call_GetFieldLevelEncryptionConfig20181105_402656948;
           Id: string): Recallable =
  ## getFieldLevelEncryptionConfig20181105
  ## Get the field-level encryption configuration information.
  ##   Id: string (required)
                                                              ##     : Request the ID for the field-level encryption configuration information.
  var path_402656961 = newJObject()
  add(path_402656961, "Id", newJString(Id))
  result = call_402656960.call(path_402656961, nil, nil, nil, nil)

var getFieldLevelEncryptionConfig20181105* = Call_GetFieldLevelEncryptionConfig20181105_402656948(
    name: "getFieldLevelEncryptionConfig20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption/{Id}/config",
    validator: validate_GetFieldLevelEncryptionConfig20181105_402656949,
    base: "/", makeUrl: url_GetFieldLevelEncryptionConfig20181105_402656950,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFieldLevelEncryptionProfile20181105_402656993 = ref object of OpenApiRestCall_402656044
proc url_UpdateFieldLevelEncryptionProfile20181105_402656995(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2018-11-05/field-level-encryption-profile/"),
                 (kind: VariableSegment, value: "Id"),
                 (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFieldLevelEncryptionProfile20181105_402656994(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Update a field-level encryption profile. 
                                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The ID of the field-level encryption profile request. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656996 = path.getOrDefault("Id")
  valid_402656996 = validateParameter(valid_402656996, JString, required = true,
                                      default = nil)
  if valid_402656996 != nil:
    section.add "Id", valid_402656996
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   If-Match: JString
                               ##           : The value of the <code>ETag</code> header that you received when retrieving the profile identity to update. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   
                                                                                                                                                                                                   ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                   ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                              ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                    ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656997 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656997 = validateParameter(valid_402656997, JString,
                                      required = false, default = nil)
  if valid_402656997 != nil:
    section.add "X-Amz-Security-Token", valid_402656997
  var valid_402656998 = header.getOrDefault("X-Amz-Signature")
  valid_402656998 = validateParameter(valid_402656998, JString,
                                      required = false, default = nil)
  if valid_402656998 != nil:
    section.add "X-Amz-Signature", valid_402656998
  var valid_402656999 = header.getOrDefault("If-Match")
  valid_402656999 = validateParameter(valid_402656999, JString,
                                      required = false, default = nil)
  if valid_402656999 != nil:
    section.add "If-Match", valid_402656999
  var valid_402657000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657000 = validateParameter(valid_402657000, JString,
                                      required = false, default = nil)
  if valid_402657000 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657000
  var valid_402657001 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657001 = validateParameter(valid_402657001, JString,
                                      required = false, default = nil)
  if valid_402657001 != nil:
    section.add "X-Amz-Algorithm", valid_402657001
  var valid_402657002 = header.getOrDefault("X-Amz-Date")
  valid_402657002 = validateParameter(valid_402657002, JString,
                                      required = false, default = nil)
  if valid_402657002 != nil:
    section.add "X-Amz-Date", valid_402657002
  var valid_402657003 = header.getOrDefault("X-Amz-Credential")
  valid_402657003 = validateParameter(valid_402657003, JString,
                                      required = false, default = nil)
  if valid_402657003 != nil:
    section.add "X-Amz-Credential", valid_402657003
  var valid_402657004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657004 = validateParameter(valid_402657004, JString,
                                      required = false, default = nil)
  if valid_402657004 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657006: Call_UpdateFieldLevelEncryptionProfile20181105_402656993;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update a field-level encryption profile. 
                                                                                         ## 
  let valid = call_402657006.validator(path, query, header, formData, body, _)
  let scheme = call_402657006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657006.makeUrl(scheme.get, call_402657006.host, call_402657006.base,
                                   call_402657006.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657006, uri, valid, _)

proc call*(call_402657007: Call_UpdateFieldLevelEncryptionProfile20181105_402656993;
           body: JsonNode; Id: string): Recallable =
  ## updateFieldLevelEncryptionProfile20181105
  ## Update a field-level encryption profile. 
  ##   body: JObject (required)
  ##   Id: string (required)
                               ##     : The ID of the field-level encryption profile request. 
  var path_402657008 = newJObject()
  var body_402657009 = newJObject()
  if body != nil:
    body_402657009 = body
  add(path_402657008, "Id", newJString(Id))
  result = call_402657007.call(path_402657008, nil, nil, nil, body_402657009)

var updateFieldLevelEncryptionProfile20181105* = Call_UpdateFieldLevelEncryptionProfile20181105_402656993(
    name: "updateFieldLevelEncryptionProfile20181105", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption-profile/{Id}/config",
    validator: validate_UpdateFieldLevelEncryptionProfile20181105_402656994,
    base: "/", makeUrl: url_UpdateFieldLevelEncryptionProfile20181105_402656995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryptionProfileConfig20181105_402656979 = ref object of OpenApiRestCall_402656044
proc url_GetFieldLevelEncryptionProfileConfig20181105_402656981(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2018-11-05/field-level-encryption-profile/"),
                 (kind: VariableSegment, value: "Id"),
                 (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFieldLevelEncryptionProfileConfig20181105_402656980(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Get the field-level encryption profile configuration information.
                                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : Get the ID for the field-level encryption profile configuration information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402656982 = path.getOrDefault("Id")
  valid_402656982 = validateParameter(valid_402656982, JString, required = true,
                                      default = nil)
  if valid_402656982 != nil:
    section.add "Id", valid_402656982
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656983 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656983 = validateParameter(valid_402656983, JString,
                                      required = false, default = nil)
  if valid_402656983 != nil:
    section.add "X-Amz-Security-Token", valid_402656983
  var valid_402656984 = header.getOrDefault("X-Amz-Signature")
  valid_402656984 = validateParameter(valid_402656984, JString,
                                      required = false, default = nil)
  if valid_402656984 != nil:
    section.add "X-Amz-Signature", valid_402656984
  var valid_402656985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656985 = validateParameter(valid_402656985, JString,
                                      required = false, default = nil)
  if valid_402656985 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656985
  var valid_402656986 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656986 = validateParameter(valid_402656986, JString,
                                      required = false, default = nil)
  if valid_402656986 != nil:
    section.add "X-Amz-Algorithm", valid_402656986
  var valid_402656987 = header.getOrDefault("X-Amz-Date")
  valid_402656987 = validateParameter(valid_402656987, JString,
                                      required = false, default = nil)
  if valid_402656987 != nil:
    section.add "X-Amz-Date", valid_402656987
  var valid_402656988 = header.getOrDefault("X-Amz-Credential")
  valid_402656988 = validateParameter(valid_402656988, JString,
                                      required = false, default = nil)
  if valid_402656988 != nil:
    section.add "X-Amz-Credential", valid_402656988
  var valid_402656989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656989 = validateParameter(valid_402656989, JString,
                                      required = false, default = nil)
  if valid_402656989 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656990: Call_GetFieldLevelEncryptionProfileConfig20181105_402656979;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the field-level encryption profile configuration information.
                                                                                         ## 
  let valid = call_402656990.validator(path, query, header, formData, body, _)
  let scheme = call_402656990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656990.makeUrl(scheme.get, call_402656990.host, call_402656990.base,
                                   call_402656990.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656990, uri, valid, _)

proc call*(call_402656991: Call_GetFieldLevelEncryptionProfileConfig20181105_402656979;
           Id: string): Recallable =
  ## getFieldLevelEncryptionProfileConfig20181105
  ## Get the field-level encryption profile configuration information.
  ##   Id: string (required)
                                                                      ##     : Get the ID for the field-level encryption profile configuration information.
  var path_402656992 = newJObject()
  add(path_402656992, "Id", newJString(Id))
  result = call_402656991.call(path_402656992, nil, nil, nil, nil)

var getFieldLevelEncryptionProfileConfig20181105* = Call_GetFieldLevelEncryptionProfileConfig20181105_402656979(
    name: "getFieldLevelEncryptionProfileConfig20181105",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/field-level-encryption-profile/{Id}/config",
    validator: validate_GetFieldLevelEncryptionProfileConfig20181105_402656980,
    base: "/", makeUrl: url_GetFieldLevelEncryptionProfileConfig20181105_402656981,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvalidation20181105_402657010 = ref object of OpenApiRestCall_402656044
proc url_GetInvalidation20181105_402657012(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path,
         "`DistributionId` is a required path parameter"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/distribution/"),
                 (kind: VariableSegment, value: "DistributionId"),
                 (kind: ConstantSegment, value: "/invalidation/"),
                 (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetInvalidation20181105_402657011(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get the information about an invalidation. 
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
                                 ##                 : The distribution's ID.
  ##   Id: 
                                                                            ## JString (required)
                                                                            ##     
                                                                            ## : 
                                                                            ## The 
                                                                            ## identifier 
                                                                            ## for 
                                                                            ## the 
                                                                            ## invalidation 
                                                                            ## request, 
                                                                            ## for 
                                                                            ## example, 
                                                                            ## <code>IDFDVBD632BHDS5</code>.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DistributionId` field"
  var valid_402657013 = path.getOrDefault("DistributionId")
  valid_402657013 = validateParameter(valid_402657013, JString, required = true,
                                      default = nil)
  if valid_402657013 != nil:
    section.add "DistributionId", valid_402657013
  var valid_402657014 = path.getOrDefault("Id")
  valid_402657014 = validateParameter(valid_402657014, JString, required = true,
                                      default = nil)
  if valid_402657014 != nil:
    section.add "Id", valid_402657014
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657015 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657015 = validateParameter(valid_402657015, JString,
                                      required = false, default = nil)
  if valid_402657015 != nil:
    section.add "X-Amz-Security-Token", valid_402657015
  var valid_402657016 = header.getOrDefault("X-Amz-Signature")
  valid_402657016 = validateParameter(valid_402657016, JString,
                                      required = false, default = nil)
  if valid_402657016 != nil:
    section.add "X-Amz-Signature", valid_402657016
  var valid_402657017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657017 = validateParameter(valid_402657017, JString,
                                      required = false, default = nil)
  if valid_402657017 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657017
  var valid_402657018 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657018 = validateParameter(valid_402657018, JString,
                                      required = false, default = nil)
  if valid_402657018 != nil:
    section.add "X-Amz-Algorithm", valid_402657018
  var valid_402657019 = header.getOrDefault("X-Amz-Date")
  valid_402657019 = validateParameter(valid_402657019, JString,
                                      required = false, default = nil)
  if valid_402657019 != nil:
    section.add "X-Amz-Date", valid_402657019
  var valid_402657020 = header.getOrDefault("X-Amz-Credential")
  valid_402657020 = validateParameter(valid_402657020, JString,
                                      required = false, default = nil)
  if valid_402657020 != nil:
    section.add "X-Amz-Credential", valid_402657020
  var valid_402657021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657021 = validateParameter(valid_402657021, JString,
                                      required = false, default = nil)
  if valid_402657021 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657022: Call_GetInvalidation20181105_402657010;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the information about an invalidation. 
                                                                                         ## 
  let valid = call_402657022.validator(path, query, header, formData, body, _)
  let scheme = call_402657022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657022.makeUrl(scheme.get, call_402657022.host, call_402657022.base,
                                   call_402657022.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657022, uri, valid, _)

proc call*(call_402657023: Call_GetInvalidation20181105_402657010;
           DistributionId: string; Id: string): Recallable =
  ## getInvalidation20181105
  ## Get the information about an invalidation. 
  ##   DistributionId: string (required)
                                                ##                 : The distribution's ID.
  ##   
                                                                                           ## Id: string (required)
                                                                                           ##     
                                                                                           ## : 
                                                                                           ## The 
                                                                                           ## identifier 
                                                                                           ## for 
                                                                                           ## the 
                                                                                           ## invalidation 
                                                                                           ## request, 
                                                                                           ## for 
                                                                                           ## example, 
                                                                                           ## <code>IDFDVBD632BHDS5</code>.
  var path_402657024 = newJObject()
  add(path_402657024, "DistributionId", newJString(DistributionId))
  add(path_402657024, "Id", newJString(Id))
  result = call_402657023.call(path_402657024, nil, nil, nil, nil)

var getInvalidation20181105* = Call_GetInvalidation20181105_402657010(
    name: "getInvalidation20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/distribution/{DistributionId}/invalidation/{Id}",
    validator: validate_GetInvalidation20181105_402657011, base: "/",
    makeUrl: url_GetInvalidation20181105_402657012,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePublicKey20181105_402657039 = ref object of OpenApiRestCall_402656044
proc url_UpdatePublicKey20181105_402657041(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/public-key/"),
                 (kind: VariableSegment, value: "Id"),
                 (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdatePublicKey20181105_402657040(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Update public key information. Note that the only value you can change is the comment.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : ID of the public key to be updated.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402657042 = path.getOrDefault("Id")
  valid_402657042 = validateParameter(valid_402657042, JString, required = true,
                                      default = nil)
  if valid_402657042 != nil:
    section.add "Id", valid_402657042
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   If-Match: JString
                               ##           : The value of the <code>ETag</code> header that you received when retrieving the public key to update. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   
                                                                                                                                                                                             ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                             ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                        ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                              ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                          ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657043 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657043 = validateParameter(valid_402657043, JString,
                                      required = false, default = nil)
  if valid_402657043 != nil:
    section.add "X-Amz-Security-Token", valid_402657043
  var valid_402657044 = header.getOrDefault("X-Amz-Signature")
  valid_402657044 = validateParameter(valid_402657044, JString,
                                      required = false, default = nil)
  if valid_402657044 != nil:
    section.add "X-Amz-Signature", valid_402657044
  var valid_402657045 = header.getOrDefault("If-Match")
  valid_402657045 = validateParameter(valid_402657045, JString,
                                      required = false, default = nil)
  if valid_402657045 != nil:
    section.add "If-Match", valid_402657045
  var valid_402657046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657046 = validateParameter(valid_402657046, JString,
                                      required = false, default = nil)
  if valid_402657046 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657046
  var valid_402657047 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657047 = validateParameter(valid_402657047, JString,
                                      required = false, default = nil)
  if valid_402657047 != nil:
    section.add "X-Amz-Algorithm", valid_402657047
  var valid_402657048 = header.getOrDefault("X-Amz-Date")
  valid_402657048 = validateParameter(valid_402657048, JString,
                                      required = false, default = nil)
  if valid_402657048 != nil:
    section.add "X-Amz-Date", valid_402657048
  var valid_402657049 = header.getOrDefault("X-Amz-Credential")
  valid_402657049 = validateParameter(valid_402657049, JString,
                                      required = false, default = nil)
  if valid_402657049 != nil:
    section.add "X-Amz-Credential", valid_402657049
  var valid_402657050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657050 = validateParameter(valid_402657050, JString,
                                      required = false, default = nil)
  if valid_402657050 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657052: Call_UpdatePublicKey20181105_402657039;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update public key information. Note that the only value you can change is the comment.
                                                                                         ## 
  let valid = call_402657052.validator(path, query, header, formData, body, _)
  let scheme = call_402657052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657052.makeUrl(scheme.get, call_402657052.host, call_402657052.base,
                                   call_402657052.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657052, uri, valid, _)

proc call*(call_402657053: Call_UpdatePublicKey20181105_402657039;
           body: JsonNode; Id: string): Recallable =
  ## updatePublicKey20181105
  ## Update public key information. Note that the only value you can change is the comment.
  ##   
                                                                                           ## body: JObject (required)
  ##   
                                                                                                                      ## Id: string (required)
                                                                                                                      ##     
                                                                                                                      ## : 
                                                                                                                      ## ID 
                                                                                                                      ## of 
                                                                                                                      ## the 
                                                                                                                      ## public 
                                                                                                                      ## key 
                                                                                                                      ## to 
                                                                                                                      ## be 
                                                                                                                      ## updated.
  var path_402657054 = newJObject()
  var body_402657055 = newJObject()
  if body != nil:
    body_402657055 = body
  add(path_402657054, "Id", newJString(Id))
  result = call_402657053.call(path_402657054, nil, nil, nil, body_402657055)

var updatePublicKey20181105* = Call_UpdatePublicKey20181105_402657039(
    name: "updatePublicKey20181105", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/public-key/{Id}/config",
    validator: validate_UpdatePublicKey20181105_402657040, base: "/",
    makeUrl: url_UpdatePublicKey20181105_402657041,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicKeyConfig20181105_402657025 = ref object of OpenApiRestCall_402656044
proc url_GetPublicKeyConfig20181105_402657027(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-11-05/public-key/"),
                 (kind: VariableSegment, value: "Id"),
                 (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPublicKeyConfig20181105_402657026(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Return public key configuration informaation
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : Request the ID for the public key configuration.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402657028 = path.getOrDefault("Id")
  valid_402657028 = validateParameter(valid_402657028, JString, required = true,
                                      default = nil)
  if valid_402657028 != nil:
    section.add "Id", valid_402657028
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657029 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657029 = validateParameter(valid_402657029, JString,
                                      required = false, default = nil)
  if valid_402657029 != nil:
    section.add "X-Amz-Security-Token", valid_402657029
  var valid_402657030 = header.getOrDefault("X-Amz-Signature")
  valid_402657030 = validateParameter(valid_402657030, JString,
                                      required = false, default = nil)
  if valid_402657030 != nil:
    section.add "X-Amz-Signature", valid_402657030
  var valid_402657031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657031 = validateParameter(valid_402657031, JString,
                                      required = false, default = nil)
  if valid_402657031 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657031
  var valid_402657032 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657032 = validateParameter(valid_402657032, JString,
                                      required = false, default = nil)
  if valid_402657032 != nil:
    section.add "X-Amz-Algorithm", valid_402657032
  var valid_402657033 = header.getOrDefault("X-Amz-Date")
  valid_402657033 = validateParameter(valid_402657033, JString,
                                      required = false, default = nil)
  if valid_402657033 != nil:
    section.add "X-Amz-Date", valid_402657033
  var valid_402657034 = header.getOrDefault("X-Amz-Credential")
  valid_402657034 = validateParameter(valid_402657034, JString,
                                      required = false, default = nil)
  if valid_402657034 != nil:
    section.add "X-Amz-Credential", valid_402657034
  var valid_402657035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657035 = validateParameter(valid_402657035, JString,
                                      required = false, default = nil)
  if valid_402657035 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657036: Call_GetPublicKeyConfig20181105_402657025;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Return public key configuration informaation
                                                                                         ## 
  let valid = call_402657036.validator(path, query, header, formData, body, _)
  let scheme = call_402657036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657036.makeUrl(scheme.get, call_402657036.host, call_402657036.base,
                                   call_402657036.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657036, uri, valid, _)

proc call*(call_402657037: Call_GetPublicKeyConfig20181105_402657025; Id: string): Recallable =
  ## getPublicKeyConfig20181105
  ## Return public key configuration informaation
  ##   Id: string (required)
                                                 ##     : Request the ID for the public key configuration.
  var path_402657038 = newJObject()
  add(path_402657038, "Id", newJString(Id))
  result = call_402657037.call(path_402657038, nil, nil, nil, nil)

var getPublicKeyConfig20181105* = Call_GetPublicKeyConfig20181105_402657025(
    name: "getPublicKeyConfig20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/public-key/{Id}/config",
    validator: validate_GetPublicKeyConfig20181105_402657026, base: "/",
    makeUrl: url_GetPublicKeyConfig20181105_402657027,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStreamingDistribution20181105_402657070 = ref object of OpenApiRestCall_402656044
proc url_UpdateStreamingDistribution20181105_402657072(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2018-11-05/streaming-distribution/"),
                 (kind: VariableSegment, value: "Id"),
                 (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateStreamingDistribution20181105_402657071(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Update a streaming distribution. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The streaming distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402657073 = path.getOrDefault("Id")
  valid_402657073 = validateParameter(valid_402657073, JString, required = true,
                                      default = nil)
  if valid_402657073 != nil:
    section.add "Id", valid_402657073
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   If-Match: JString
                               ##           : The value of the <code>ETag</code> header that you received when retrieving the streaming distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   
                                                                                                                                                                                                               ## X-Amz-Content-Sha256: JString
  ##   
                                                                                                                                                                                                                                               ## X-Amz-Algorithm: JString
  ##   
                                                                                                                                                                                                                                                                          ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                                                                                                                                ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                                                                                                                            ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657074 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657074 = validateParameter(valid_402657074, JString,
                                      required = false, default = nil)
  if valid_402657074 != nil:
    section.add "X-Amz-Security-Token", valid_402657074
  var valid_402657075 = header.getOrDefault("X-Amz-Signature")
  valid_402657075 = validateParameter(valid_402657075, JString,
                                      required = false, default = nil)
  if valid_402657075 != nil:
    section.add "X-Amz-Signature", valid_402657075
  var valid_402657076 = header.getOrDefault("If-Match")
  valid_402657076 = validateParameter(valid_402657076, JString,
                                      required = false, default = nil)
  if valid_402657076 != nil:
    section.add "If-Match", valid_402657076
  var valid_402657077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657077 = validateParameter(valid_402657077, JString,
                                      required = false, default = nil)
  if valid_402657077 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657077
  var valid_402657078 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657078 = validateParameter(valid_402657078, JString,
                                      required = false, default = nil)
  if valid_402657078 != nil:
    section.add "X-Amz-Algorithm", valid_402657078
  var valid_402657079 = header.getOrDefault("X-Amz-Date")
  valid_402657079 = validateParameter(valid_402657079, JString,
                                      required = false, default = nil)
  if valid_402657079 != nil:
    section.add "X-Amz-Date", valid_402657079
  var valid_402657080 = header.getOrDefault("X-Amz-Credential")
  valid_402657080 = validateParameter(valid_402657080, JString,
                                      required = false, default = nil)
  if valid_402657080 != nil:
    section.add "X-Amz-Credential", valid_402657080
  var valid_402657081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657081 = validateParameter(valid_402657081, JString,
                                      required = false, default = nil)
  if valid_402657081 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657083: Call_UpdateStreamingDistribution20181105_402657070;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update a streaming distribution. 
                                                                                         ## 
  let valid = call_402657083.validator(path, query, header, formData, body, _)
  let scheme = call_402657083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657083.makeUrl(scheme.get, call_402657083.host, call_402657083.base,
                                   call_402657083.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657083, uri, valid, _)

proc call*(call_402657084: Call_UpdateStreamingDistribution20181105_402657070;
           body: JsonNode; Id: string): Recallable =
  ## updateStreamingDistribution20181105
  ## Update a streaming distribution. 
  ##   body: JObject (required)
  ##   Id: string (required)
                               ##     : The streaming distribution's id.
  var path_402657085 = newJObject()
  var body_402657086 = newJObject()
  if body != nil:
    body_402657086 = body
  add(path_402657085, "Id", newJString(Id))
  result = call_402657084.call(path_402657085, nil, nil, nil, body_402657086)

var updateStreamingDistribution20181105* = Call_UpdateStreamingDistribution20181105_402657070(
    name: "updateStreamingDistribution20181105", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/streaming-distribution/{Id}/config",
    validator: validate_UpdateStreamingDistribution20181105_402657071,
    base: "/", makeUrl: url_UpdateStreamingDistribution20181105_402657072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistributionConfig20181105_402657056 = ref object of OpenApiRestCall_402656044
proc url_GetStreamingDistributionConfig20181105_402657058(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2018-11-05/streaming-distribution/"),
                 (kind: VariableSegment, value: "Id"),
                 (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStreamingDistributionConfig20181105_402657057(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Get the configuration information about a streaming distribution. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
                                 ##     : The streaming distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_402657059 = path.getOrDefault("Id")
  valid_402657059 = validateParameter(valid_402657059, JString, required = true,
                                      default = nil)
  if valid_402657059 != nil:
    section.add "Id", valid_402657059
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657060 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657060 = validateParameter(valid_402657060, JString,
                                      required = false, default = nil)
  if valid_402657060 != nil:
    section.add "X-Amz-Security-Token", valid_402657060
  var valid_402657061 = header.getOrDefault("X-Amz-Signature")
  valid_402657061 = validateParameter(valid_402657061, JString,
                                      required = false, default = nil)
  if valid_402657061 != nil:
    section.add "X-Amz-Signature", valid_402657061
  var valid_402657062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657062 = validateParameter(valid_402657062, JString,
                                      required = false, default = nil)
  if valid_402657062 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657062
  var valid_402657063 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657063 = validateParameter(valid_402657063, JString,
                                      required = false, default = nil)
  if valid_402657063 != nil:
    section.add "X-Amz-Algorithm", valid_402657063
  var valid_402657064 = header.getOrDefault("X-Amz-Date")
  valid_402657064 = validateParameter(valid_402657064, JString,
                                      required = false, default = nil)
  if valid_402657064 != nil:
    section.add "X-Amz-Date", valid_402657064
  var valid_402657065 = header.getOrDefault("X-Amz-Credential")
  valid_402657065 = validateParameter(valid_402657065, JString,
                                      required = false, default = nil)
  if valid_402657065 != nil:
    section.add "X-Amz-Credential", valid_402657065
  var valid_402657066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657066 = validateParameter(valid_402657066, JString,
                                      required = false, default = nil)
  if valid_402657066 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657067: Call_GetStreamingDistributionConfig20181105_402657056;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the configuration information about a streaming distribution. 
                                                                                         ## 
  let valid = call_402657067.validator(path, query, header, formData, body, _)
  let scheme = call_402657067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657067.makeUrl(scheme.get, call_402657067.host, call_402657067.base,
                                   call_402657067.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657067, uri, valid, _)

proc call*(call_402657068: Call_GetStreamingDistributionConfig20181105_402657056;
           Id: string): Recallable =
  ## getStreamingDistributionConfig20181105
  ## Get the configuration information about a streaming distribution. 
  ##   Id: string 
                                                                       ## (required)
                                                                       ##     
                                                                       ## : 
                                                                       ## The 
                                                                       ## streaming 
                                                                       ## distribution's 
                                                                       ## ID.
  var path_402657069 = newJObject()
  add(path_402657069, "Id", newJString(Id))
  result = call_402657068.call(path_402657069, nil, nil, nil, nil)

var getStreamingDistributionConfig20181105* = Call_GetStreamingDistributionConfig20181105_402657056(
    name: "getStreamingDistributionConfig20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/streaming-distribution/{Id}/config",
    validator: validate_GetStreamingDistributionConfig20181105_402657057,
    base: "/", makeUrl: url_GetStreamingDistributionConfig20181105_402657058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributionsByWebACLId20181105_402657087 = ref object of OpenApiRestCall_402656044
proc url_ListDistributionsByWebACLId20181105_402657089(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "WebACLId" in path, "`WebACLId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2018-11-05/distributionsByWebACLId/"),
                 (kind: VariableSegment, value: "WebACLId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDistributionsByWebACLId20181105_402657088(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   WebACLId: JString (required)
                                 ##           : The ID of the AWS WAF web ACL that you want to list the associated distributions. If you specify "null" for the ID, the request returns a list of the distributions that aren't associated with a web ACL. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `WebACLId` field"
  var valid_402657090 = path.getOrDefault("WebACLId")
  valid_402657090 = validateParameter(valid_402657090, JString, required = true,
                                      default = nil)
  if valid_402657090 != nil:
    section.add "WebACLId", valid_402657090
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
                                  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## MaxItems: JString
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## distributions 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## CloudFront 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## return 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## maximum 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## default 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## values 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## both 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## 100.
  section = newJObject()
  var valid_402657091 = query.getOrDefault("Marker")
  valid_402657091 = validateParameter(valid_402657091, JString,
                                      required = false, default = nil)
  if valid_402657091 != nil:
    section.add "Marker", valid_402657091
  var valid_402657092 = query.getOrDefault("MaxItems")
  valid_402657092 = validateParameter(valid_402657092, JString,
                                      required = false, default = nil)
  if valid_402657092 != nil:
    section.add "MaxItems", valid_402657092
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657093 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657093 = validateParameter(valid_402657093, JString,
                                      required = false, default = nil)
  if valid_402657093 != nil:
    section.add "X-Amz-Security-Token", valid_402657093
  var valid_402657094 = header.getOrDefault("X-Amz-Signature")
  valid_402657094 = validateParameter(valid_402657094, JString,
                                      required = false, default = nil)
  if valid_402657094 != nil:
    section.add "X-Amz-Signature", valid_402657094
  var valid_402657095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657095 = validateParameter(valid_402657095, JString,
                                      required = false, default = nil)
  if valid_402657095 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657095
  var valid_402657096 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657096 = validateParameter(valid_402657096, JString,
                                      required = false, default = nil)
  if valid_402657096 != nil:
    section.add "X-Amz-Algorithm", valid_402657096
  var valid_402657097 = header.getOrDefault("X-Amz-Date")
  valid_402657097 = validateParameter(valid_402657097, JString,
                                      required = false, default = nil)
  if valid_402657097 != nil:
    section.add "X-Amz-Date", valid_402657097
  var valid_402657098 = header.getOrDefault("X-Amz-Credential")
  valid_402657098 = validateParameter(valid_402657098, JString,
                                      required = false, default = nil)
  if valid_402657098 != nil:
    section.add "X-Amz-Credential", valid_402657098
  var valid_402657099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657099 = validateParameter(valid_402657099, JString,
                                      required = false, default = nil)
  if valid_402657099 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657100: Call_ListDistributionsByWebACLId20181105_402657087;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
                                                                                         ## 
  let valid = call_402657100.validator(path, query, header, formData, body, _)
  let scheme = call_402657100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657100.makeUrl(scheme.get, call_402657100.host, call_402657100.base,
                                   call_402657100.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657100, uri, valid, _)

proc call*(call_402657101: Call_ListDistributionsByWebACLId20181105_402657087;
           WebACLId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listDistributionsByWebACLId20181105
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ##   
                                                                                  ## Marker: string
                                                                                  ##         
                                                                                  ## : 
                                                                                  ## Use 
                                                                                  ## <code>Marker</code> 
                                                                                  ## and 
                                                                                  ## <code>MaxItems</code> 
                                                                                  ## to 
                                                                                  ## control 
                                                                                  ## pagination 
                                                                                  ## of 
                                                                                  ## results. 
                                                                                  ## If 
                                                                                  ## you 
                                                                                  ## have 
                                                                                  ## more 
                                                                                  ## than 
                                                                                  ## <code>MaxItems</code> 
                                                                                  ## distributions 
                                                                                  ## that 
                                                                                  ## satisfy 
                                                                                  ## the 
                                                                                  ## request, 
                                                                                  ## the 
                                                                                  ## response 
                                                                                  ## includes 
                                                                                  ## a 
                                                                                  ## <code>NextMarker</code> 
                                                                                  ## element. 
                                                                                  ## To 
                                                                                  ## get 
                                                                                  ## the 
                                                                                  ## next 
                                                                                  ## page 
                                                                                  ## of 
                                                                                  ## results, 
                                                                                  ## submit 
                                                                                  ## another 
                                                                                  ## request. 
                                                                                  ## For 
                                                                                  ## the 
                                                                                  ## value 
                                                                                  ## of 
                                                                                  ## <code>Marker</code>, 
                                                                                  ## specify 
                                                                                  ## the 
                                                                                  ## value 
                                                                                  ## of 
                                                                                  ## <code>NextMarker</code> 
                                                                                  ## from 
                                                                                  ## the 
                                                                                  ## last 
                                                                                  ## response. 
                                                                                  ## (For 
                                                                                  ## the 
                                                                                  ## first 
                                                                                  ## request, 
                                                                                  ## omit 
                                                                                  ## <code>Marker</code>.) 
  ##   
                                                                                                           ## WebACLId: string (required)
                                                                                                           ##           
                                                                                                           ## : 
                                                                                                           ## The 
                                                                                                           ## ID 
                                                                                                           ## of 
                                                                                                           ## the 
                                                                                                           ## AWS 
                                                                                                           ## WAF 
                                                                                                           ## web 
                                                                                                           ## ACL 
                                                                                                           ## that 
                                                                                                           ## you 
                                                                                                           ## want 
                                                                                                           ## to 
                                                                                                           ## list 
                                                                                                           ## the 
                                                                                                           ## associated 
                                                                                                           ## distributions. 
                                                                                                           ## If 
                                                                                                           ## you 
                                                                                                           ## specify 
                                                                                                           ## "null" 
                                                                                                           ## for 
                                                                                                           ## the 
                                                                                                           ## ID, 
                                                                                                           ## the 
                                                                                                           ## request 
                                                                                                           ## returns 
                                                                                                           ## a 
                                                                                                           ## list 
                                                                                                           ## of 
                                                                                                           ## the 
                                                                                                           ## distributions 
                                                                                                           ## that 
                                                                                                           ## aren't 
                                                                                                           ## associated 
                                                                                                           ## with 
                                                                                                           ## a 
                                                                                                           ## web 
                                                                                                           ## ACL. 
  ##   
                                                                                                                   ## MaxItems: string
                                                                                                                   ##           
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## maximum 
                                                                                                                   ## number 
                                                                                                                   ## of 
                                                                                                                   ## distributions 
                                                                                                                   ## that 
                                                                                                                   ## you 
                                                                                                                   ## want 
                                                                                                                   ## CloudFront 
                                                                                                                   ## to 
                                                                                                                   ## return 
                                                                                                                   ## in 
                                                                                                                   ## the 
                                                                                                                   ## response 
                                                                                                                   ## body. 
                                                                                                                   ## The 
                                                                                                                   ## maximum 
                                                                                                                   ## and 
                                                                                                                   ## default 
                                                                                                                   ## values 
                                                                                                                   ## are 
                                                                                                                   ## both 
                                                                                                                   ## 100.
  var path_402657102 = newJObject()
  var query_402657103 = newJObject()
  add(query_402657103, "Marker", newJString(Marker))
  add(path_402657102, "WebACLId", newJString(WebACLId))
  add(query_402657103, "MaxItems", newJString(MaxItems))
  result = call_402657101.call(path_402657102, query_402657103, nil, nil, nil)

var listDistributionsByWebACLId20181105* = Call_ListDistributionsByWebACLId20181105_402657087(
    name: "listDistributionsByWebACLId20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/distributionsByWebACLId/{WebACLId}",
    validator: validate_ListDistributionsByWebACLId20181105_402657088,
    base: "/", makeUrl: url_ListDistributionsByWebACLId20181105_402657089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource20181105_402657104 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource20181105_402657106(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource20181105_402657105(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## List tags for a CloudFront resource.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
                                  ##           :  An ARN of a CloudFront resource.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `Resource` field"
  var valid_402657107 = query.getOrDefault("Resource")
  valid_402657107 = validateParameter(valid_402657107, JString, required = true,
                                      default = nil)
  if valid_402657107 != nil:
    section.add "Resource", valid_402657107
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657108 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657108 = validateParameter(valid_402657108, JString,
                                      required = false, default = nil)
  if valid_402657108 != nil:
    section.add "X-Amz-Security-Token", valid_402657108
  var valid_402657109 = header.getOrDefault("X-Amz-Signature")
  valid_402657109 = validateParameter(valid_402657109, JString,
                                      required = false, default = nil)
  if valid_402657109 != nil:
    section.add "X-Amz-Signature", valid_402657109
  var valid_402657110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657110 = validateParameter(valid_402657110, JString,
                                      required = false, default = nil)
  if valid_402657110 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657110
  var valid_402657111 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657111 = validateParameter(valid_402657111, JString,
                                      required = false, default = nil)
  if valid_402657111 != nil:
    section.add "X-Amz-Algorithm", valid_402657111
  var valid_402657112 = header.getOrDefault("X-Amz-Date")
  valid_402657112 = validateParameter(valid_402657112, JString,
                                      required = false, default = nil)
  if valid_402657112 != nil:
    section.add "X-Amz-Date", valid_402657112
  var valid_402657113 = header.getOrDefault("X-Amz-Credential")
  valid_402657113 = validateParameter(valid_402657113, JString,
                                      required = false, default = nil)
  if valid_402657113 != nil:
    section.add "X-Amz-Credential", valid_402657113
  var valid_402657114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657114 = validateParameter(valid_402657114, JString,
                                      required = false, default = nil)
  if valid_402657114 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657115: Call_ListTagsForResource20181105_402657104;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List tags for a CloudFront resource.
                                                                                         ## 
  let valid = call_402657115.validator(path, query, header, formData, body, _)
  let scheme = call_402657115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657115.makeUrl(scheme.get, call_402657115.host, call_402657115.base,
                                   call_402657115.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657115, uri, valid, _)

proc call*(call_402657116: Call_ListTagsForResource20181105_402657104;
           Resource: string): Recallable =
  ## listTagsForResource20181105
  ## List tags for a CloudFront resource.
  ##   Resource: string (required)
                                         ##           :  An ARN of a CloudFront resource.
  var query_402657117 = newJObject()
  add(query_402657117, "Resource", newJString(Resource))
  result = call_402657116.call(nil, query_402657117, nil, nil, nil)

var listTagsForResource20181105* = Call_ListTagsForResource20181105_402657104(
    name: "listTagsForResource20181105", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2018-11-05/tagging#Resource",
    validator: validate_ListTagsForResource20181105_402657105, base: "/",
    makeUrl: url_ListTagsForResource20181105_402657106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource20181105_402657118 = ref object of OpenApiRestCall_402656044
proc url_TagResource20181105_402657120(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource20181105_402657119(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Add tags to a CloudFront resource.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
                                  ##           :  An ARN of a CloudFront resource.
  ##   
                                                                                  ## Operation: JString (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `Resource` field"
  var valid_402657121 = query.getOrDefault("Resource")
  valid_402657121 = validateParameter(valid_402657121, JString, required = true,
                                      default = nil)
  if valid_402657121 != nil:
    section.add "Resource", valid_402657121
  var valid_402657134 = query.getOrDefault("Operation")
  valid_402657134 = validateParameter(valid_402657134, JString, required = true,
                                      default = newJString("Tag"))
  if valid_402657134 != nil:
    section.add "Operation", valid_402657134
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657135 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657135 = validateParameter(valid_402657135, JString,
                                      required = false, default = nil)
  if valid_402657135 != nil:
    section.add "X-Amz-Security-Token", valid_402657135
  var valid_402657136 = header.getOrDefault("X-Amz-Signature")
  valid_402657136 = validateParameter(valid_402657136, JString,
                                      required = false, default = nil)
  if valid_402657136 != nil:
    section.add "X-Amz-Signature", valid_402657136
  var valid_402657137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657137 = validateParameter(valid_402657137, JString,
                                      required = false, default = nil)
  if valid_402657137 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657137
  var valid_402657138 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657138 = validateParameter(valid_402657138, JString,
                                      required = false, default = nil)
  if valid_402657138 != nil:
    section.add "X-Amz-Algorithm", valid_402657138
  var valid_402657139 = header.getOrDefault("X-Amz-Date")
  valid_402657139 = validateParameter(valid_402657139, JString,
                                      required = false, default = nil)
  if valid_402657139 != nil:
    section.add "X-Amz-Date", valid_402657139
  var valid_402657140 = header.getOrDefault("X-Amz-Credential")
  valid_402657140 = validateParameter(valid_402657140, JString,
                                      required = false, default = nil)
  if valid_402657140 != nil:
    section.add "X-Amz-Credential", valid_402657140
  var valid_402657141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657141 = validateParameter(valid_402657141, JString,
                                      required = false, default = nil)
  if valid_402657141 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657143: Call_TagResource20181105_402657118;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Add tags to a CloudFront resource.
                                                                                         ## 
  let valid = call_402657143.validator(path, query, header, formData, body, _)
  let scheme = call_402657143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657143.makeUrl(scheme.get, call_402657143.host, call_402657143.base,
                                   call_402657143.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657143, uri, valid, _)

proc call*(call_402657144: Call_TagResource20181105_402657118; Resource: string;
           body: JsonNode; Operation: string = "Tag"): Recallable =
  ## tagResource20181105
  ## Add tags to a CloudFront resource.
  ##   Resource: string (required)
                                       ##           :  An ARN of a CloudFront resource.
  ##   
                                                                                       ## body: JObject (required)
  ##   
                                                                                                                  ## Operation: string (required)
  var query_402657145 = newJObject()
  var body_402657146 = newJObject()
  add(query_402657145, "Resource", newJString(Resource))
  if body != nil:
    body_402657146 = body
  add(query_402657145, "Operation", newJString(Operation))
  result = call_402657144.call(nil, query_402657145, nil, nil, body_402657146)

var tagResource20181105* = Call_TagResource20181105_402657118(
    name: "tagResource20181105", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/tagging#Operation=Tag&Resource",
    validator: validate_TagResource20181105_402657119, base: "/",
    makeUrl: url_TagResource20181105_402657120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource20181105_402657147 = ref object of OpenApiRestCall_402656044
proc url_UntagResource20181105_402657149(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource20181105_402657148(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Remove tags from a CloudFront resource.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
                                  ##           :  An ARN of a CloudFront resource.
  ##   
                                                                                  ## Operation: JString (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `Resource` field"
  var valid_402657150 = query.getOrDefault("Resource")
  valid_402657150 = validateParameter(valid_402657150, JString, required = true,
                                      default = nil)
  if valid_402657150 != nil:
    section.add "Resource", valid_402657150
  var valid_402657151 = query.getOrDefault("Operation")
  valid_402657151 = validateParameter(valid_402657151, JString, required = true,
                                      default = newJString("Untag"))
  if valid_402657151 != nil:
    section.add "Operation", valid_402657151
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657152 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657152 = validateParameter(valid_402657152, JString,
                                      required = false, default = nil)
  if valid_402657152 != nil:
    section.add "X-Amz-Security-Token", valid_402657152
  var valid_402657153 = header.getOrDefault("X-Amz-Signature")
  valid_402657153 = validateParameter(valid_402657153, JString,
                                      required = false, default = nil)
  if valid_402657153 != nil:
    section.add "X-Amz-Signature", valid_402657153
  var valid_402657154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657154 = validateParameter(valid_402657154, JString,
                                      required = false, default = nil)
  if valid_402657154 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657154
  var valid_402657155 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657155 = validateParameter(valid_402657155, JString,
                                      required = false, default = nil)
  if valid_402657155 != nil:
    section.add "X-Amz-Algorithm", valid_402657155
  var valid_402657156 = header.getOrDefault("X-Amz-Date")
  valid_402657156 = validateParameter(valid_402657156, JString,
                                      required = false, default = nil)
  if valid_402657156 != nil:
    section.add "X-Amz-Date", valid_402657156
  var valid_402657157 = header.getOrDefault("X-Amz-Credential")
  valid_402657157 = validateParameter(valid_402657157, JString,
                                      required = false, default = nil)
  if valid_402657157 != nil:
    section.add "X-Amz-Credential", valid_402657157
  var valid_402657158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657158 = validateParameter(valid_402657158, JString,
                                      required = false, default = nil)
  if valid_402657158 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657160: Call_UntagResource20181105_402657147;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove tags from a CloudFront resource.
                                                                                         ## 
  let valid = call_402657160.validator(path, query, header, formData, body, _)
  let scheme = call_402657160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657160.makeUrl(scheme.get, call_402657160.host, call_402657160.base,
                                   call_402657160.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657160, uri, valid, _)

proc call*(call_402657161: Call_UntagResource20181105_402657147;
           Resource: string; body: JsonNode; Operation: string = "Untag"): Recallable =
  ## untagResource20181105
  ## Remove tags from a CloudFront resource.
  ##   Resource: string (required)
                                            ##           :  An ARN of a CloudFront resource.
  ##   
                                                                                            ## body: JObject (required)
  ##   
                                                                                                                       ## Operation: string (required)
  var query_402657162 = newJObject()
  var body_402657163 = newJObject()
  add(query_402657162, "Resource", newJString(Resource))
  if body != nil:
    body_402657163 = body
  add(query_402657162, "Operation", newJString(Operation))
  result = call_402657161.call(nil, query_402657162, nil, nil, body_402657163)

var untagResource20181105* = Call_UntagResource20181105_402657147(
    name: "untagResource20181105", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2018-11-05/tagging#Operation=Untag&Resource",
    validator: validate_UntagResource20181105_402657148, base: "/",
    makeUrl: url_UntagResource20181105_402657149,
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}